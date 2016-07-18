#!/usr/bin/env python

from __future__ import print_function
import sys
import yaml
import os
from string import Template
import pwd
import re


class Config:

    config = {'syncs': {}}
    supervisor_conf_folder = '/etc/supervisor/conf.d/'
    unison_template_path = './supervisor.unison.tpl.conf'
    fswatch_template_path = './supervisor.fswatch.tpl.conf'

    def read_yaml(self, config_file):
        with open(config_file, 'r') as stream:
            try:
                return yaml.load(stream)
            except yaml.YAMLError as exc:
                print(exc)

    def write_supervisor_conf_unison(self, conf):
        template = open(self.unison_template_path)
        with open(self.supervisor_conf_folder + 'unison' + conf['name'] + '.conf', 'w') as f:
            f.write(Template(template.read()).substitute(conf))

    def write_supervisor_conf_fswatch(self, conf, reverse):
        template = open(self.fswatch_template_path)
        reverse_str = '-reverse' if reverse else ''
        volume_watch = conf['volume'] if reverse else conf['volume'] + '.magic'
        conf.update({'volume_watch': volume_watch, 'reverse': reverse_str})
        supervisor_conf = self.supervisor_conf_folder + 'fswatch' + conf['name'] + reverse_str + '.conf'
        with open(supervisor_conf, 'w') as f:
            f.write(Template(template.read()).substitute(conf))

    def write_supervisor_conf(self):
        if 'syncs' in self.config:
            for i, (volume, conf) in enumerate(self.config['syncs'].iteritems(), 1):
                conf.update({'port': 5000 + int(i)})
                self.write_supervisor_conf_unison(conf)
                self.write_supervisor_conf_fswatch(conf, False)
                self.write_supervisor_conf_fswatch(conf, True)

    def create_user(self, user, uid):
        if uid:
            print("Uid is set to " + str(uid))
            uid_str = " -u " + str(uid) + " "
            # if uid doesn't exist on the system
            if int(uid) not in [x[2] for x in pwd.getpwall()]:
                # if user doesn't exist on the system
                if user not in [y[0] for y in pwd.getpwall()]:
                    cmd="useradd " + user + uid_str + " -m"
                    print(cmd)
                    os.system(cmd)
                else:
                    cmd="usermod " + uid_str + user
                    print(cmd)
                    os.system(cmd)
            else:
                # get username with uid
                for existing_user in pwd.getpwall():
                    if existing_user[2] == int(uid):
                        user_name = existing_user[0]
                cmd="mkdir -p /home/" + user + " && usermod --home /home/" + user + " --login " + user + " " + str(user_name) + " && chown -R " + user + " /home/" + user
                print(cmd)
                os.system(cmd)
        else:
            if user not in [x[0] for x in pwd.getpwall()]:
                cmd="useradd " + user + " -m"
                print(cmd)
                os.system(cmd)
            else:
                print("user already exists")

    def set_permissions(self, user, folder):
        if user != 'root':
            os.system("chown " + user + " " + folder)
            os.system("chown -R " + user + " " + folder + ".magic")

    def set_defaults(self):
        if 'syncs' in self.config:
            for i, (volume, conf) in enumerate(self.config['syncs'].iteritems(), 1):
                self.config['syncs'][volume]['volume'] = volume
                self.config['syncs'][volume]['name'] = re.sub(r'\/', '-', volume)
                if 'user' in conf:
                    user = conf['user']
                    self.config['syncs'][volume]['homedir'] = '/home/' + conf['user']
                elif os.environ['SYNC_USER']:
                    user = os.environ['SYNC_USER']
                    self.config['syncs'][volume]['user'] = os.environ['SYNC_USER']
                    self.config['syncs'][volume]['homedir'] = '/home/' + os.environ['SYNC_USER']
                else:
                    self.config['syncs'][volume]['user'] = 'root'
                    self.config['syncs'][volume]['homedir'] = '/root'
                if 'uid' in conf:
                    uid = conf['uid']
                elif os.environ['SYNC_UID']:
                    uid = os.environ['SYNC_UID']
                    self.config['syncs'][volume]['uid'] = os.environ['SYNC_UID']
                self.create_user(user, uid)
                self.set_permissions(user, volume)

    def merge_discovered_mounts(self):
        mounts = self.read_yaml('/mounts.yml')
        for mount in mounts['mounts']:
            print(mount)
            if '.magic' in mount:
                if not self.config or mount not in self.config['syncs']:
                    self.config['syncs'][mount.replace('.magic', '')] = {}
                    print(self.config)

    def initial_sync(self):
        if 'syncs' in self.config:
            for volume, conf in self.config['syncs'].iteritems():
                os.system('cp -ar ' + volume + '.magic/. ' + volume)

    def set(self, config_file):
        if config_file:
            self.config = self.read_yaml(config_file)
        self.merge_discovered_mounts()
        self.set_defaults()
        self.write_supervisor_conf()
        self.initial_sync()

c = Config()
c.set(sys.argv[1])


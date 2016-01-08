import os

import xonsh.environ

if 'VIRTUALENV_HOME' not in __xonsh_env__:
    $VIRTUALENV_HOME = os.path.join($HOME, '.virtualenvs')

class VixCmd:
    DISPATCH = {
        # subcmd      implemented in
        # ----------- --------------
        'activate':   'activate',
        'deactivate': 'deactivate',
        'help':       'usage',
        'ls':         'listenvs',
        'rm':         'rmvirtualenv',
        'usage':      'usage',
    }

    def __call__(self, args, stdin=None):
        if len(args) < 1:
            return self.usage()
        cmd, args = args[0], args[1:]
        if cmd not in self.DISPATCH:
            return self.usage()
        impl = getattr(self, self.DISPATCH[cmd])
        return impl(args)

    def __init__(self):
        # in case `deactivate` is called before `activate` is
        self._saved_vars = {}

    # save values of these vars upon `activate`, and then restore the old value upon `deactivate`
    SAVE_VARS = {'PYTHONHOME', 'PIP_USER', 'PROMPT'}

    # these vars should get an empty value upon `activate`
    EMPTY_VARS = {'PYTHONHOME', 'PIP_USER'}

    def activate(self, args):
        if len(args) != 1:
            return self.usage()

        target = os.path.join($VIRTUALENV_HOME, args[0])
        if not os.path.exists(target):
            return self.usage()

        # deactivate v.env if non-trivial
        if __xonsh_env__.get('VIRTUAL_ENV', False):
            self.deactivate([])

        $VIRTUAL_ENV = target
        self._saved_vars = {
            v: __xonsh_env__.get(v)
            for v in self.SAVE_VARS
        }

        for v in self.EMPTY_VARS:
            __xonsh_env__.pop(v, None)

        $PATH.insert(0, os.path.join($VIRTUAL_ENV, 'bin'))

        if 'PROMPT' not in __xonsh_env__:
            $PROMPT = xonsh.environ.DEFAULT_PROMPT
        $PROMPT = '({}) '.format(args[0]) + $PROMPT


    def deactivate(self, args):
        if not __xonsh_env__.get('VIRTUAL_ENV', False):
            print('No virtualenv is active.')
            return
        virtual_bin = os.path.join($VIRTUAL_ENV, 'bin')
        while virtual_bin in $PATH:
            $PATH.remove(virtual_bin)
        for name, value in self._saved_vars.items():
            ${name} = value
        self._saved_vars = {}
        del $VIRTUAL_ENV


    def listenvs(self, args):
        for envdir in sorted(
                entry for entry in os.listdir($VIRTUALENV_HOME)
                if os.path.isdir(os.path.join($VIRTUALENV_HOME, entry))):
            print(envdir)


    def rmvirtualenv(self, args):
        rm -r @(os.path.join($VIRTUALENV_HOME, args[0]))


    def usage(self):
        print('consult non-existent documentation for usage')


aliases['vix'] = VixCmd()

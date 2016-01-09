import os

import xonsh.environ

if 'VIRTUALENV_HOME' not in __xonsh_env__:
    $VIRTUALENV_HOME = os.path.join($HOME, '.virtualenvs')

if $VIRTUAL_ENV and 'vix' in aliases:
    try:
        vix deactivate
    except:
        pass


# work around `name in __xonsh_env__` always returning true
__notfound = object()

def defined(name):
    """
    Return ``True`` if
    """
    val = __xonsh_env__.get(name, __notfound)
    return False if val is __notfound else True


class VixCmd:
    DISPATCH = {
        # subcmd      implemented in
        # ----------- --------------
        'activate':   'activate',
        'deactivate': 'deactivate',
        'help':       'usage',
        'ls':         'listenvs',
        'new':        'new',
        'rm':         'rmvirtualenv',
        'usage':      'usage',
        'which':      'which',
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
        self._current_env = None
        # in case `deactivate` is called before `activate` is
        self._saved_vars = {}

    # save values of these vars upon `activate`, and then restore the old value upon `deactivate`
    SAVE_VARS = {'PYTHONHOME', 'PIP_USER', 'PROMPT'}

    # these vars should get an empty value upon `activate`
    EMPTY_VARS = {'PYTHONHOME', 'PIP_USER'}


    def new(self, args):
        if len(args) != 1:
            return self.usage()

        name = args[0]
        target = os.path.join($VIRTUALENV_HOME, name)
        if os.path.exists(target):
            sys.stderr.write(
                "ERROR: a directory `{}` already exists!"
                .format(name))
            return

        python -m virtualenv @(target)
        self.activate([name])


    def activate(self, args):
        if len(args) != 1:
            return self.usage()

        if __xonsh_env__.get('VIRTUALENVHOME', False):
            sys.stderr.write(
                "Please set environment variable `VIRTUALENV_HOME` first.")
            return

        name = args[0]
        target = os.path.join($VIRTUALENV_HOME, name)
        if not os.path.exists(target):
            return self.usage()

        # deactivate v.env if non-trivial
        if __xonsh_env__.get('VIRTUAL_ENV', False):
            self.deactivate([])

        $VIRTUAL_ENV = target
        for v in self.SAVE_VARS:
            # only save vars that are actually defined
            if defined(v):
                self._saved_vars[v] = ${v}

        for v in self.EMPTY_VARS:
            if defined(v):
                del ${v}

        $PATH.insert(0, os.path.join($VIRTUAL_ENV, 'bin'))

        if 'PROMPT' not in __xonsh_env__:
            $PROMPT = xonsh.environ.DEFAULT_PROMPT
        $PROMPT = '({}) '.format(args[0]) + $PROMPT

        self._current_env = name


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
        self._current_env = None


    def listenvs(self, args):
        if __xonsh_env__.get('VIRTUALENVHOME', False):
            sys.stderr.write(
                "Please set environment variable `VIRTUALENV_HOME` first.")
            return

        for envdir in sorted(
                entry for entry in os.listdir($VIRTUALENV_HOME)
                if os.path.isdir(os.path.join($VIRTUALENV_HOME, entry))):
            print(envdir)


    def rmvirtualenv(self, args):
        if __xonsh_env__.get('VIRTUALENVHOME', False):
            sys.stderr.write(
                "Please set environment variable `VIRTUALENV_HOME` first.")
            return

        rm -r @(os.path.join($VIRTUALENV_HOME, args[0]))


    def usage(self, args=()):
        print('consult non-existent documentation for usage')


    def which(self, args=()):
        if self._current_env:
            print(self._current_env)


aliases['vix'] = VixCmd()

# compatibility aliases for virtualenvwrapper
aliases['workon'] = 'vix activate'
aliases['mkvirtualenv'] = 'vix new'
aliases['rmvirtualenv'] = 'vix rm'
aliases['lsvirtualenv'] = 'vix ls'

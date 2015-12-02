import os

import xonsh.environ

if 'VIRTUALXONSH_HOME' not in __xonsh_env__:
    $VIRTUALENV_HOME = os.path.join($HOME, '.virtualenvs')

def __install_vf():
    envvars = {'PYTHONHOME', 'PIP_USER', 'PROMPT'}
    join = os.path.join

    def activate(args):
        if len(args) != 1:
            return usage()

        target = join($VIRTUALENV_HOME, args[0])
        if not os.path.exists(target):
            return usage()

        if __xonsh_env__.get('VIRTUAL_ENV'):
            deactivate([])

        $VIRTUAL_ENV = target
        $_VX_OLDVARS = {
            v: __xonsh_env__.get(v)
            for v in envvars
        }
        for v in envvars:
            if v in __xonsh_env__:
                del __xonsh_env__[v]

        $PATH.insert(0, join($VIRTUAL_ENV, 'bin'))
        if 'PROMPT' not in __xonsh_env__:
            $PROMPT = xonsh.environ.DEFAULT_PROMPT
        $PROMPT = '({}) '.format(args[0]) + $PROMPT

    def deactivate(args):
        if 'VIRTUAL_ENV' not in __xonsh_env__:
            print('No virtualenv is activated')
            return
        virtual_bin = join($VIRTUAL_ENV, 'bin')
        $PATH = [p for p in $PATH if p != virtual_bin]
        if '_VX_OLDVARS' in __xonsh_env__:
            for v in $_VX_OLDVARS:
                if v:
                    ${v} = $_VX_OLDVARS[v]
                else:
                    del $v
        del $VIRTUAL_ENV


    def listenvs(args):
        for env in sorted(os.listdir($VIRTUALENV_HOME)):
            print(env)

    def rmvirtualenv(args):
        rm -r @(join($VIRTUALENV_HOME, args[0]))

    def usage():
        print('consult non-existent documentation for usage')

    DISPATCH = {
        'activate': activate,
        'deactivate': deactivate,
        'ls': listenvs,
        'rm': rmvirtualenv,
    }

    def vf(args, stdin=None):
        if len(args) < 1:
            return usage()
        cmd, args = args[0], args[1:]
        if cmd not in DISPATCH:
            return usage()
        return DISPATCH[cmd](args)

    aliases['vf'] = vf

__install_vf()

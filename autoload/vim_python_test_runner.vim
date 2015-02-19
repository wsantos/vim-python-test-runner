set makeprg=cat\ /tmp/test_results.txt
set efm+=%C\ %.%#,%A\ \ File\ \"%f\"\\,\ line\ %l%.%#,%Z%[%^\ ]%\\@=%m

if !has('python')
    finish
endif

" -----------------------------
" Add our directory to the path
" -----------------------------
python import sys
python import vim
python sys.path.append(vim.eval('expand("<sfile>:h")'))

function! vim_python_test_runner#RunDesiredTests(command_to_run)
python << endPython
import os
from sys import platform as _platform
from vim_python_test_runner import *

def get_proper_command(desired_command, current_directory):
    current_line_index = vim.current.window.cursor[0]
    FUNCTIONS = {
        "django_app": lambda: get_command_to_run_the_current_app(current_directory),
        "django_file": lambda: get_command_to_run_the_current_file(current_directory),
        "django_class": lambda: get_command_to_run_the_current_class(current_directory, current_line_index, vim.current.buffer),
        "django_method": lambda: get_command_to_run_the_current_method(current_directory, current_line_index, vim.current.buffer),
        "nose_file": lambda: get_command_to_run_current_file_with_nosetests(vim.current.buffer.name),
        "nose_class": lambda: get_command_to_run_current_class_with_nosetests(vim.current.buffer.name, current_line_index, vim.current.buffer),
        "nose_method": lambda: get_command_to_run_current_method_with_nosetests(vim.current.buffer.name, current_line_index, vim.current.buffer),
        "nose_base_method": lambda: get_command_to_run_current_base_method_with_nosetests(vim.current.buffer.name, current_line_index, vim.current.buffer),
        "rerun": lambda: get_command_to_rerun_last_tests()
    }
    return FUNCTIONS[desired_command]()

def activate_virtualenv():
    if 'VIRTUAL_ENV' in os.environ:
        project_base_dir = os.environ['VIRTUAL_ENV']
        sys.path.insert(0, project_base_dir)
        activate_this = os.path.join(project_base_dir, 'bin/activate')
        return "source {0} &&".format(activate_this)
    else:
        return ""

def run_desired_command_for_os(command_to_run):

    virtual_env = activate_virtualenv()

    if "nose" in vim.eval("a:command_to_run") or "nose" in command_to_run:
        vim.command("{0}{1} 2>&1 | tee /tmp/test_results.txt".format(virtual_env, command_to_run))
    elif _platform == 'linux' or _platform == 'linux2':
        vim.command(":!{0} python {1} 2>&1 | tee /tmp/test_results.txt".format(virtual_env, command_to_run))
    elif _platform == 'darwin' and virtual_env:
        vim.command(":!{0} python {1} 2>&1 | tee /tmp/test_results.txt".format(virtual_env, command_to_run))
    elif _platform == 'darwin': # TODO: Enable virtualenv with sudo
        vim.command(":!sudo python {0} 2>&1 | tee /tmp/test_results.txt".format(command_to_run))

def main():
    current_directory = os.sep.join([dir for dir in vim.current.buffer.name.split(os.sep) if dir])
    try:
        command_to_run = get_proper_command(vim.eval("a:command_to_run"), current_directory)
    except Exception as e:
        print(e)
    run_desired_command_for_os(command_to_run)
    vim.command('silent make! | cw')

vim.command('wall')
main()
endPython
endfunction

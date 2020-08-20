#!/usr/bin/env python

import shutil
import subprocess
import json
import sys
import os
import hashlib
import base64
import shlex

query = json.load(sys.stdin)

dist_dir = query['dist_dir']
package_file = query.get('package_file', None)
output_file = os.path.join(dist_dir, 'output.zip')


def clean():
    shutil.rmtree(dist_dir, ignore_errors=True)


def install_dependencies():
    package_file_name = os.path.basename(package_file) if package_file else None

    if package_file_name == 'package.json':
        install_npm()
    elif package_file == 'requirements.txt':
        install_pip()
    elif package_file == 'Pipfile':
        install_pip_env()
    else:
        copy_source()


def install_npm():
    assert package_file
    install_dir = f'{dist_dir}/nodejs'
    dist_package_file = f'{install_dir}/package.json'
    os.makedirs(install_dir, exist_ok=True)
    shutil.copy(package_file, dist_package_file)
    subprocess.run(
        ['npm', 'install', '--production', '--no-optional', '--no-package-lock', '--prefix', f'{install_dir}/']
    )


def install_pip():
    assert package_file
    install_dir = '$DIST_DIR/python'
    os.makedirs(install_dir, exist_ok=True)
    subprocess.run(
        ['pip', 'install', '--target', install_dir, f'--requirement={package_file}']
    )


def install_pip_env():
    assert package_file
    source_dir = os.path.dirname(package_file)
    install_dir = f'{dist_dir}/python'
    dist_requirement_file = f'{install_dir}/requirements.txt'
    os.makedirs(install_dir, exist_ok=True)
    subprocess.run(
        ['pipenv', 'lock', '--requirements', '>', dist_requirement_file],
        cwd=source_dir
    )
    subprocess.run(
        ['pip', 'install', '--target', install_dir, f'--requirement={dist_requirement_file}']
    )


def copy_source():
    source_dir = query['source_dir']
    source_type = query['source_type']
    rsync_pattern = shlex.split(query.get('rsync_pattern', ''))
    install_dir = f'{dist_dir}/{source_type}'
    os.makedirs(install_dir, exist_ok=True)
    subprocess.run(['rsync', '-az', *rsync_pattern, '.', install_dir], cwd=source_dir)


def zip():
    base = os.path.basename(output_file)
    name = os.path.splitext(base)[0]
    shutil.make_archive(name, 'zip', dist_dir)
    shutil.move(base, dist_dir)


def output():
    json.dump({
        'output_file': output_file,
        'output_hash': hash_file(output_file)
    }, sys.stdout, indent=2)
    sys.stdout.write('\n')


def hash_file(filepath):
    file_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            file_hash.update(chunk)
    return base64.b64encode(file_hash.digest()).decode('utf-8')


if __name__ == '__main__':
    clean()
    install_dependencies()
    zip()
    output()

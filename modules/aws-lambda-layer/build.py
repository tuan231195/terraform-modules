#!/usr/bin/env python

import shutil
import subprocess
import json
import sys
import os
import hashlib
import base64
import tempfile
import time
import zipfile
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
    elif package_file_name == 'requirements.txt':
        install_pip()
    elif package_file_name == 'Pipfile':
        install_pip_env()
    else:
        copy_source()


def install_npm():
    assert package_file
    install_dir = f'{dist_dir}/nodejs'
    dist_package_file = f'{install_dir}/package.json'
    os.makedirs(install_dir, exist_ok=True)
    shutil.copy(package_file, dist_package_file)
    subprocess.check_call(
        ['npm', 'install', '--production', '--no-optional', '--no-package-lock', '--prefix', f'{install_dir}/'],
        stdout=sys.stderr
    )


def install_pip():
    assert package_file
    install_dir = '$DIST_DIR/python'
    os.makedirs(install_dir, exist_ok=True)

    subprocess.check_call(
        ['pip', 'install', '--target', install_dir, f'--requirement={package_file}'],
        stdout=sys.stderr
    )


def install_pip_env():
    assert package_file
    source_dir = os.path.dirname(package_file)
    install_dir = f'{dist_dir}/python'
    dist_requirement_file = f'{install_dir}/requirements.txt'
    os.makedirs(install_dir, exist_ok=True)
    subprocess.check_call(
        ['pipenv', 'lock', '--requirements', '>', dist_requirement_file],
        cwd=source_dir,
        stdout=sys.stderr
    )
    subprocess.check_call(
        ['pip', 'install', '--target', install_dir, f'--requirement={dist_requirement_file}'],
        stdout=sys.stderr
    )


def copy_source():
    source_dir = query['source_dir']
    source_type = query['source_type']
    rsync_pattern = shlex.split(query.get('rsync_pattern', ''))
    install_dir = f'{dist_dir}/{source_type}'
    os.makedirs(install_dir, exist_ok=True)
    subprocess.check_call(['rsync', '-az', *rsync_pattern, '.', install_dir], cwd=source_dir,
                          stdout=sys.stderr)


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


def zip_file(source_dir, destination_file):
    base = os.path.basename(destination_file)
    name, _ = os.path.splitext(base)
    temp_zip_file = os.path.join(tempfile.gettempdir(), str(time.time()) + '.zip')

    new_zip = zipfile.ZipFile(temp_zip_file, 'w')
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            current_file = os.path.join(root, file)
            info = zipfile.ZipInfo.from_file(current_file, arcname=os.path.relpath(current_file, source_dir))
            info.date_time = (2000, 1, 1, 0, 0, 0)
            with open(current_file, 'rb') as fd:
                new_zip.writestr(info, fd.read(), compress_type=zipfile.ZIP_DEFLATED)
    new_zip.close()
    shutil.move(temp_zip_file, destination_file)


if __name__ == '__main__':
    clean()
    install_dependencies()
    zip_file(dist_dir, output_file)
    output()

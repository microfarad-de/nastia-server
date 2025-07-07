#!/usr/bin/env python
#
# System wide lock for use on unix based systems
#
# Based on the ilock Python module but uses the mkdir atomic command
# instead of Portalocker, which is unstable on some embedded systems
# such as the Victron Venus OS.
#
# Please visit:
#   http://www.microfarad.de
#   http://www.github.com/microfarad-de
#
# Copyright (C) 2025 Karim Hraibi (khraibi@gmail.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
import os
from hashlib import sha256
from tempfile import gettempdir
from time import time, sleep


class ULockException(Exception):
    pass


class ULock:
    def __init__(self, name, timeout=None, check_interval=0.25, reentrant=False, lock_directory=None):
        self._timeout = timeout if timeout is not None else 10**8
        self._check_interval = check_interval
        self._reentrant = reentrant
        self._enter_count = 0

        lock_directory = gettempdir() if lock_directory is None else lock_directory
        unique_token = sha256(name.encode()).hexdigest()
        self._lockpath = os.path.join(lock_directory, 'ulock-' + unique_token + '.lock')

    def __enter__(self):
        if self._enter_count > 0:
            if self._reentrant:
                self._enter_count += 1
                return self
            raise ULockException('Trying to re-enter a non-reentrant lock')

        start_time = time()
        while time() - start_time < self._timeout:
            try:
                os.mkdir(self._lockpath)
                self._enter_count = 1
                return self
            except FileExistsError:
                pass
            except PermissionError:
                pass  # Silently ignore and retry

            sleep(min(self._check_interval, self._timeout))

        raise ULockException('Timeout was reached while acquiring the lock')

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._enter_count -= 1
        if self._enter_count > 0:
            return

        try:
            os.rmdir(self._lockpath)
        except FileNotFoundError:
            pass  # Already deleted
        except PermissionError:
            pass  # Silently ignore


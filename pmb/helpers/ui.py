"""
Copyright 2017 Clayton Craft

This file is part of pmbootstrap.

pmbootstrap is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

pmbootstrap is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with pmbootstrap.  If not, see <http://www.gnu.org/licenses/>.
"""
import os
import glob


def list(args):
    """
    Get all UIs, for which aports are available
    :returns: ["none", "postmarketos-ui-one", "psotmarketos-ui-two", ...]
    """
    ret = []
    for path in glob.glob(args.aports + "/postmarketos-ui-*"):
        ui = os.path.basename(path).split("-", 2)[2]
        ret.append(ui)
    ret.append('none')
    return ret

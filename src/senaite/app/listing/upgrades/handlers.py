# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.APP.LISTING.
#
# SENAITE.APP.LISTING is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Copyright 2018-2025 by it's authors.
# Some rights reserved, see README and LICENSE.

from senaite.app.listing import logger

PROFILE_ID = "profile-senaite.app.listing:default"


def to_2600(portal_setup):
    """Update to version 2.6.0

    :param portal_setup: The portal_setup tool
    """

    logger.info("Run all import steps from SENAITE APP LISTING ...")
    context = portal_setup._getImportContext(PROFILE_ID)
    portal = context.getSite()  # noqa
    portal_setup.runAllImportStepsFromProfile(PROFILE_ID)
    logger.info("Run all import steps from SENAITE APP LISTING [DONE]")


def to_2500(portal_setup):
    """Update to version 2.5.0

    :param portal_setup: The portal_setup tool
    """

    logger.info("Run all import steps from SENAITE APP LISTING ...")
    context = portal_setup._getImportContext(PROFILE_ID)
    portal = context.getSite()  # noqa
    portal_setup.runAllImportStepsFromProfile(PROFILE_ID)
    logger.info("Run all import steps from SENAITE APP LISTING [DONE]")


def to_2400(portal_setup):
    """Update to version 2.4.0

    :param portal_setup: The portal_setup tool
    """

    logger.info("Run all import steps from SENAITE APP LISTING ...")
    context = portal_setup._getImportContext(PROFILE_ID)
    portal = context.getSite()  # noqa
    portal_setup.runAllImportStepsFromProfile(PROFILE_ID)
    logger.info("Run all import steps from SENAITE APP LISTING [DONE]")


def to_2300(portal_setup):
    """Update to version 2.3.0

    :param portal_setup: The portal_setup tool
    """

    logger.info("Run all import steps from SENAITE APP LISTING ...")
    context = portal_setup._getImportContext(PROFILE_ID)
    portal = context.getSite()  # noqa
    portal_setup.runAllImportStepsFromProfile(PROFILE_ID)
    logger.info("Run all import steps from SENAITE APP LISTING [DONE]")

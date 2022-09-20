# -*- coding: utf-8 -*-

from senaite.app.listing import logger

PROFILE_ID = "profile-senaite.app.listing:default"


def to_2300(portal_setup):
    """Update to version 2.3.0

    :param portal_setup: The portal_setup tool
    """

    logger.info("Run all import steps from SENAITE APP LISTING ...")
    context = portal_setup._getImportContext(PROFILE_ID)
    portal = context.getSite()  # noqa
    portal_setup.runAllImportStepsFromProfile(PROFILE_ID)
    logger.info("Run all import steps from SENAITE APP LISTING [DONE]")

# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.CORE.LISTING
#
# Copyright 2018 by it's authors.

import logging

from zope.i18nmessageid import MessageFactory

# Defining a Message Factory for when this product is internationalized.
senaiteMessageFactory = MessageFactory("senaite.core.listing")

logger = logging.getLogger("senaite.core.listing")

# convenience import
from senaite.core.listing.view import ListingView


def initialize(context):
    """Initializer called when used as a Zope 2 product."""
    logger.info("*** Initializing SENAITE.CORE.LISTING ***")

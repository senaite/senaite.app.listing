# -*- coding: utf-8 -*-

from plone.app.layout.viewlets import ViewletBase
from Products.Five.browser.pagetemplatefile import ViewPageTemplateFile


class ResourcesViewlet(ViewletBase):
    template = ViewPageTemplateFile("../static/resources.pt")

    def index(self):
        return self.template()

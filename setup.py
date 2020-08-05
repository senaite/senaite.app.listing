# -*- coding: utf-8 -*-

from setuptools import setup, find_packages

version = "1.5.1"

with open("docs/About.rst", "r") as fh:
    long_description = fh.read()

with open("docs/Changelog.rst", "r") as fh:
    long_description += "\n\n"
    long_description += "Changelog\n"
    long_description += "=========\n"
    long_description += fh.read()

setup(
    name="senaite.core.listing",
    version=version,
    description="ReactJS powered listing tables for SENAITE LIMS",
    long_description=long_description,
    # Get more strings from
    # http://pypi.python.org/pypi?:action=list_classifiers
    classifiers=[
        "Programming Language :: Python",
        "Framework :: Plone",
        "Framework :: Zope2",
    ],
    keywords=['senaite', 'lims', 'opensource', 'reactjs'],
    author="SENAITE Foundation",
    author_email="hello@senaite.com",
    url="https://github.com/senaite/senaite.core.listing",
    license="GPLv2",
    packages=find_packages("src", exclude=["ez_setup"]),
    package_dir={"": "src"},
    namespace_packages=["senaite", "senaite.core"],
    include_package_data=True,
    zip_safe=False,
    install_requires=[
        "setuptools",
        "senaite.core",
    ],
    extras_require={
        "test": [
            "Products.PloneTestCase",
            "plone.app.testing",
            "unittest2",
        ]
    },
    entry_points="""
      # -*- Entry points: -*-
      [z3c.autoinclude.plugin]
      target = plone
      """,
)

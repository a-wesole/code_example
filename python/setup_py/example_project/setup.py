from setuptools import setup, find_packages

setup(
     name='example2022',
     version='0.1.0',
     packages=find_packages(include=['exampleproject', 'exampleproject.*'])
     )


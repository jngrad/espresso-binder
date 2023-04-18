# Minimal Dockerfiles for ESPResSo and Binder

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/jngrad/espresso-binder/4.2.1)

Setup a JupyterLab environment to run ESPResSo on the Binder platform.

Paste this repository url in https://mybinder.org to start using ESPResSo in the
cloud ([direct link](https://mybinder.org/v2/gh/jngrad/espresso-binder/4.2.1)).

Uses ESPResSo 4.2.1 built with the default configuration and no dependencies.

## Developer's guide

Please refer to the following chapters in online user guides:

- Docker user guide: [Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- Binder user guide: [Use a Dockerfile for your Binder repository](https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html)
- Binder user guide: [binder-examples/minimal-dockerfile](https://github.com/binder-examples/minimal-dockerfile)
- ESPResSo user guide: [Installing requirements on Ubuntu Linux](https://espressomd.github.io/doc4.2.1/installation.html#installing-requirements-on-ubuntu-linux)
- ESPResSo user guide: [Interactive notebooks](https://espressomd.github.io/doc4.2.1/running.html#interactive-notebooks)

### Build an image containing ESPResSo

[![Docker Image Size](https://img.shields.io/docker/image-size/jngrad/espresso/4.2.1?style=social)](https://hub.docker.com/r/jngrad/espresso)

Build the base image containing the ESPResSo shared objects:

```sh
docker build --tag jngrad/espresso:4.2.1 -f Dockerfile-espresso .
docker login
docker push jngrad/espresso:4.2.1
docker logout
```

A multi-stage approach is used in [Dockerfile-espresso](Dockerfile-espresso)
to keep the image size to a minimum. No ESPResSo dependencies are installed.
The Python dependencies will be installed in the Binder image.

To build different ESPResSo configurations, add arguments to the build command,
such as `--build-arg WITH_CUDA=ON` to enable CUDA support (case sensitive).

### Build an image suitable for Binder

Build the Binder image containing the Python dependencies from
[requirements.txt](requirements.txt):

```sh
docker build -t my-image --build-arg NB_USER=espresso --build-arg NB_UID=1000 .
```

Test the ESPResSo binaries by running the testsuite:

```sh
docker run --user espresso -it my-image bash
mkdir testsuite
tar xfz /app/testsuite.tar.gz --strip-components=1 --directory=testsuite
cd testsuite
sed -i 's/def test_script/def _skip_script/' h5md.py
time bash -e suite.sh
```

Test the Jupyter environment:

```sh
docker run -it --rm -p 8888:8888 my-image jupyter lab --NotebookApp.default_url=/lab/ --ip=0.0.0.0 --port=8888
```

By default, the home directory is populated with the ESPResSo tutorials in
two folders: one called "exercises" with solutions contained in hidden cells
and one called "solutions" with the solutions already pasted in code cells.

### Technical aspects

Check image sizes:

```sh
docker image ls
```

```
REPOSITORY        TAG                 IMAGE ID       CREATED         SIZE
my-image          latest              6d0774d00d40   36 minutes ago  1.08GB
jngrad/espresso   f4d09d96            4fb311cfb577   42 minutes ago  611MB
```

Show installed packages:

```sh
apt list --installed
du -hc .local/lib/python3.9/site-packages/ | sort -h
```

Show runner technical information:

```sh
$ echo "CPU limit: ${CPU_LIMIT}"
$ echo "RAM limit: $((MEM_LIMIT / 1024 / 1024)) MiB"
```
```
CPU limit: 1.0
RAM limit: 2048 MB
```

Show server URL and secret token:

```python
import subprocess
out = subprocess.run(["jupyter", "notebook", "list"], capture_output=True)
url = out.stdout.decode("utf-8").split("\n")[1].split()[0]
url = url.replace("http://0.0.0.0:8888/", "https://hub.mybinder.org/")
print(url)
```

This URL can be used to edit and share files in the same session,
but it is not possible to edit the same file at the same time.
When sharing this URL with third parties, they will be able to
shut down the session for everyone with `File > Shut Down`;
instruct them to use `File > Log Out` to leave the session.
If you have JavaScript enabled, it is more convenient to do
`pip install jupyterlab-link-share`, which introduces a new
tab called `Shared` from which one can get the URL and token
with `Share > Share Jupyter Server Link`.

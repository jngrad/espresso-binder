FROM jngrad/espresso:summer_school_2026
ENV PYTHONPATH="${PYTHON3_SITEARCH}:${PYTHON3_DISTARCH}"

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
WORKDIR ${HOME}
RUN chown -R ${NB_UID} ${HOME}
USER ${USER}
COPY plugin.jupyterlab-settings ${HOME}/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/plugin.jupyterlab-settings
RUN python3 -m venv venv
ENV VIRTUAL_ENV="${HOME}/venv"
ENV PATH="${VIRTUAL_ENV}/bin${PATH:+:$PATH}"
ENV OMP_PROC_BIND=false
RUN pip install --no-cache --upgrade pip \
&& pip install --no-cache --constraint /app/requirements.txt notebook jupyterlab jupyterhub ipympl jupyter-server-proxy numpy scipy matplotlib pint tqdm zndraw \
&& mkdir -p tutorials/exercises \
&& tar xfz /app/tutorials.tar.gz --strip-components=1 --directory=tutorials/exercises \
&& cp /app/importlib_wrapper.py tutorials/ \
&& mv tutorials/exercises/convert.py tutorials/exercises/Readme.md tutorials/ \
&& sed -ri '/End of tutorials landing page/,/# Video lectures/{/End of tutorials landing page/!{/# Video lectures/!d}}; /^  .+[^ ]$/d;' tutorials/Readme.md \
&& sed -ri 's|/tmp/espresso/maintainer/parsing|/app|' tutorials/convert.py \
&& cp -r tutorials/exercises tutorials/solutions \
&& for f in tutorials/exercises/*/*.ipynb; do python tutorials/convert.py cells --to-md ${f}; done \
&& for f in tutorials/solutions/*/*.ipynb; do python tutorials/convert.py cells --to-py ${f}; done \
&& for f in tutorials/solutions/*/*.ipynb; do python tutorials/convert.py cells --remove-empty-cells ${f}; done \
&& tar xfz /app/samples.tar.gz

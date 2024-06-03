FROM jngrad/espresso:devel
ENV PYTHONPATH="${PYTHON3_SITEARCH}:${PYTHON3_DISTARCH}"
# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache "notebook" "jupyterlab==4.0.8" "ipympl==0.9.4"

# create user with a home directory
ARG NB_USER=user
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}
ENV PATH ${HOME}/.local/bin${PATH:+:$PATH}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
WORKDIR ${HOME}
COPY plugin.jupyterlab-settings ${HOME}/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/plugin.jupyterlab-settings
RUN chown -R ${NB_UID} ${HOME}
USER ${USER}
RUN pip install --no-cache --user numpy scipy matplotlib pint tqdm --constraint /app/requirements.txt && \
    mkdir -p tutorials/exercises && \
    tar xfz /app/tutorials.tar.gz --strip-components=1 --directory=tutorials/exercises && \
    cp /app/importlib_wrapper.py tutorials/ && \
    mv tutorials/exercises/convert.py tutorials/exercises/Readme.md tutorials/ && \
    sed -i 's/espressomd.lb.LBFluidWalberlaGPU/espressomd.lb.LBFluidWalberla/; s/, \\"CUDA\\"//;' tutorials/exercises/*/*.ipynb && \
    sed -ri '/End of tutorials landing page/,/# Video lectures/{/End of tutorials landing page/!{/# Video lectures/!d}}; /^  .+[^ ]$/d;' tutorials/Readme.md && \
    cp -r tutorials/exercises tutorials/solutions && \
    for f in tutorials/exercises/*/*.ipynb; do python tutorials/convert.py cells --to-md ${f}; done && \
    for f in tutorials/solutions/*/*.ipynb; do python tutorials/convert.py cells --remove-empty-cells ${f}; done && \
    tar xfz /app/samples.tar.gz

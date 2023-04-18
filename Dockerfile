FROM jngrad/espresso:4.2.1
ENV PYTHONPATH="${PYTHON3_SITEARCH}:${PYTHON3_DISTARCH}"
# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache "notebook==6.5.1" "jupyterlab==3.4.8"

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
    sed -i 's/espressomd.lb.LBFluidGPU/espressomd.lb.LBFluid/; s/LB_BOUNDARIES_GPU/LB_BOUNDARIES/;' tutorials/exercises/lattice_boltzmann/lattice_boltzmann_poiseuille_flow.ipynb && \
    sed -i 's/espressomd.lb.LBFluidGPU/espressomd.lb.LBFluid/; s/, \\"CUDA\\"\]/]/;' tutorials/exercises/active_matter/active_matter.ipynb && \
    sed -ri '/End of tutorials landing page/,/# Video lectures/{/End of tutorials landing page/!{/# Video lectures/!d}}; /^  .+[^ ]$/d;' tutorials/Readme.md && \
    cp -r tutorials/exercises tutorials/solutions && \
    for f in tutorials/exercises/*/*.ipynb; do python tutorials/convert.py exercise2 --to-jupyterlab ${f}; done && \
    for f in tutorials/solutions/*/*.ipynb; do python tutorials/convert.py exercise2 --to-py ${f}; done && \
    for f in tutorials/solutions/*/*.ipynb; do python tutorials/convert.py exercise2 --remove-empty-cells ${f}; done && \
    tar xfz /app/samples.tar.gz

# Binder image for the Sage ComplexBall / Go Mie demonstration.
# Sage's maintained Binder image avoids rebuilding SageMath from source.
FROM ghcr.io/sagemath/sage-binder-env:10.9

USER root

ARG NB_USER=user
ARG NB_UID=1000
ARG GO_VERSION=1.22.12

ENV NB_USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV HOME=/home/${NB_USER}
ENV PATH="/usr/local/go/bin:/home/${NB_USER}/go/bin:/home/sage/sage:/home/sage/sage/local/bin:/home/sage/sage/venv/bin:${PATH}"

RUN if id -u ${NB_UID} >/dev/null 2>&1; then \
        EXISTING_USER=$(id -nu ${NB_UID}); \
        EXISTING_GROUP=$(id -gn ${NB_UID}); \
        if [ "${EXISTING_GROUP}" != "${NB_USER}" ]; then \
            groupmod -n ${NB_USER} ${EXISTING_GROUP} || true; \
        fi; \
        if [ "${EXISTING_USER}" != "${NB_USER}" ]; then \
            usermod -l ${NB_USER} -d ${HOME} ${EXISTING_USER}; \
            mkdir -p ${HOME}; \
            chown ${NB_USER}:${NB_USER} ${HOME}; \
        fi; \
    else \
        groupadd -g ${NB_UID} ${NB_USER} || true; \
        useradd -m -s /bin/bash -u ${NB_UID} -g ${NB_USER} ${NB_USER}; \
    fi

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
       | tar -C /usr/local -xz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=${NB_USER}:${NB_USER} . ${HOME}/

# Apply the exact public PR commit to Sage's real source tree.  The build must
# fail if the patch no longer applies; there is deliberately no fallback API.
RUN cd /home/sage/sage \
    && git apply --check ${HOME}/PR_dda09a7_spherical_bessel_sequences.patch \
    && git apply ${HOME}/PR_dda09a7_spherical_bessel_sequences.patch \
    && SAGE_PACKAGE_DIR=$(/usr/bin/sage -python -c "from pathlib import Path; import sage; print(Path(sage.__file__).resolve().parent)") \
    && ln -sfn /home/sage/sage/src/sage/functions/all.py "${SAGE_PACKAGE_DIR}/functions/all.py" \
    && ln -sfn /home/sage/sage/src/sage/functions/bessel.py "${SAGE_PACKAGE_DIR}/functions/bessel.py" \
    && /usr/bin/sage -c "import inspect; from pathlib import Path; from sage.all import spherical_bessel_J_sequence, spherical_bessel_Y_sequence, spherical_hankel1_sequence; expected=Path('/home/sage/sage/src/sage/functions/bessel.py').resolve(); assert all(Path(inspect.getsourcefile(f)).resolve() == expected for f in (spherical_bessel_J_sequence, spherical_bessel_Y_sequence, spherical_hankel1_sequence)); print('PATCHED SAGE API CHECK: PASS')"

USER ${NB_USER}
WORKDIR ${HOME}

# Register SageMath and GoNB in the same JupyterLab instance.
RUN mkdir -p $(/usr/bin/sage -sh -c 'jupyter --data-dir')/kernels \
    && ln -sf $(/usr/bin/sage -sh -c 'echo $SAGE_VENV')/share/jupyter/kernels/sagemath \
       $(/usr/bin/sage -sh -c 'jupyter --data-dir')/kernels/sagemath \
    && go install github.com/janpfeifer/gonb@v0.9.6 \
    && go install golang.org/x/tools/cmd/goimports@v0.20.0 \
    && gonb --install \
    && go mod download

RUN mkdir -p ${HOME}/.jupyter \
    && printf '%s\n' \
       'c.ServerApp.default_url = "/lab/tree/01_Sage_Spherical_Sequence_API_Export.ipynb"' \
       > ${HOME}/.jupyter/jupyter_server_config.py

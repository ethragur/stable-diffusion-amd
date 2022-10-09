FROM rocm/dev-ubuntu-20.04:latest

SHELL ["/bin/bash", "-c"]

RUN apt update \
 && apt install --no-install-recommends -y curl wget git \
 && apt-get clean

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh -O ~/miniconda.sh \
 && bash ~/miniconda.sh -b -p $HOME/miniconda \
 && $HOME/miniconda/bin/conda init

COPY . /root/stable-diffusion

RUN eval "$($HOME/miniconda/bin/conda shell.bash hook)" \
 && cd /root/stable-diffusion \
 && conda env create -f environment.yaml \
 && conda activate ldm \
 && pip install gradio==3.1.7 \
 && pip3 install --upgrade torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/rocm5.1.1

VOLUME /root/.cache
VOLUME /data
VOLUME /output

ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860
EXPOSE 7860

RUN ln -s /data /root/stable-diffusion/models/ldm/stable-diffusion-v1 \
 && mkdir -p /output /root/stable-diffusion/outputs \
 && ln -s /output /root/stable-diffusion/outputs/txt2img-samples

ENV HSA_OVERRIDE_GFX_VERSION=10.3.0
WORKDIR /root/stable-diffusion

ENTRYPOINT ["/root/stable-diffusion/docker-bootstrap.sh"]
CMD python optimizedSD/txt2img_gradio.py

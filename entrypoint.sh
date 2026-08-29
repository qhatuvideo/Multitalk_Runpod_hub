#!/bin/bash
set -e

export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_HUB_DISABLE_PROGRESS_BARS=1

NETWORK_ROOT="/runpod-volume"
PERSISTENT_WEIGHTS="$NETWORK_ROOT/weights"
INSTALL_FLAG="$NETWORK_ROOT/all_installed.flag"

echo ">>> Preparing persistent Network Volume..."

mkdir -p "$PERSISTENT_WEIGHTS"

# /MultiTalk/weights debe apuntar SIEMPRE al volumen persistente
if [ -L /MultiTalk/weights ]; then
    rm -f /MultiTalk/weights
elif [ -d /MultiTalk/weights ]; then
    rm -rf /MultiTalk/weights
fi

ln -s "$PERSISTENT_WEIGHTS" /MultiTalk/weights

if [ ! -f "$INSTALL_FLAG" ]; then

    echo ">>> First persistent setup. Downloading models to Network Volume..."
    cd /MultiTalk

    hf download Wan-AI/Wan2.1-I2V-14B-480P \
        --local-dir "$PERSISTENT_WEIGHTS/Wan2.1-I2V-14B-480P"

    hf download TencentGameMate/chinese-wav2vec2-base \
        --local-dir "$PERSISTENT_WEIGHTS/chinese-wav2vec2-base"

    hf download TencentGameMate/chinese-wav2vec2-base model.safetensors \
        --revision refs/pr/1 \
        --local-dir "$PERSISTENT_WEIGHTS/chinese-wav2vec2-base"

    hf download hexgrad/Kokoro-82M \
        --local-dir "$PERSISTENT_WEIGHTS/Kokoro-82M"

    hf download MeiGen-AI/MeiGen-MultiTalk \
        --local-dir "$PERSISTENT_WEIGHTS/MeiGen-MultiTalk"

    if [ -f "$PERSISTENT_WEIGHTS/Wan2.1-I2V-14B-480P/diffusion_pytorch_model.safetensors.index.json" ]; then
        mv \
        "$PERSISTENT_WEIGHTS/Wan2.1-I2V-14B-480P/diffusion_pytorch_model.safetensors.index.json" \
        "$PERSISTENT_WEIGHTS/Wan2.1-I2V-14B-480P/diffusion_pytorch_model.safetensors.index.json_old"
    fi

    wget -q \
    https://huggingface.co/vrgamedevgirl84/Wan14BT2VFusioniX/resolve/main/FusionX_LoRa/Wan2.1_I2V_14B_FusionX_LoRA.safetensors \
    -O "$PERSISTENT_WEIGHTS/Wan2.1_I2V_14B_FusionX_LoRA.safetensors"

    wget -q \
    https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors \
    -O "$PERSISTENT_WEIGHTS/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors"

    echo ">>> Setting up symbolic links for models..."

    ln -sf \
    "$PERSISTENT_WEIGHTS/MeiGen-MultiTalk/diffusion_pytorch_model.safetensors.index.json" \
    "$PERSISTENT_WEIGHTS/Wan2.1-I2V-14B-480P/diffusion_pytorch_model.safetensors.index.json"

    ln -sf \
    "$PERSISTENT_WEIGHTS/MeiGen-MultiTalk/multitalk.safetensors" \
    "$PERSISTENT_WEIGHTS/Wan2.1-I2V-14B-480P/multitalk.safetensors"

    touch "$INSTALL_FLAG"

    echo ">>> Persistent model setup complete."

else
    echo ">>> Models already exist on Network Volume. Skipping downloads."
fi

echo ">>> Starting application..."

cd /
python handler.py

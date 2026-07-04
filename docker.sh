#!/bin/bash

CONTAINER_NAME=aoc2026-env-container
IMAGE_NAME=aoc2026-env

build_image() {
  if [ -n "$(docker images -q ${IMAGE_NAME})" ]; then
    echo "Image ${IMAGE_NAME} already exists."
    echo "To remove it, run: docker rmi ${IMAGE_NAME}"
else
    docker build -t ${IMAGE_NAME} .
fi
}

clean_all() {
    echo "Removing all containers based on ${IMAGE_NAME}..."
    # 找出所有基於此 image 的容器 ID,一次刪光
    docker ps -aq --filter ancestor=${IMAGE_NAME} | xargs -r docker rm -f

    echo "Removing image: ${IMAGE_NAME}"
    docker rmi ${IMAGE_NAME}
}


run_container() {
    if [ -n "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
        # container 存在，再判斷在不在跑
        if [ -n "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
            # running → 直接 exec 進去
            docker exec -it ${CONTAINER_NAME} bash
        else
            # stopped → 先 start 再 exec
            docker start ${CONTAINER_NAME}
            docker exec -it ${CONTAINER_NAME} bash
        fi
    else
        # not existed → docker run 建新的
        docker run -it \
            --name ${CONTAINER_NAME} \
            -v "$PWD":/workspace \
            -w /workspace \
            ${IMAGE_NAME} \
            bash
    fi
}
case "${1:-}" in
    run)
        build_image
        run_container
        ;;
    clean)
        clean_all
        ;;
    rebuild)
        clean_all
        build_image
        run_container
        ;;
    *)
        echo "Usage: $0 {run|clean|rebuild}"
        ;;
esac
# synb0_25iso_app

This is a dummy repo so singularity hub can host the singularity container.

[Docker Hub](https://hub.docker.com/r/justinblaber/synb0_25iso/tags/)

[Singularity Hub](https://www.singularity-hub.org/collections/3102)

# Run Instructions:
For docker:
```
sudo docker run --rm \
-v $(pwd)/INPUTS/:/INPUTS/ \
-v $(pwd)/OUTPUTS:/OUTPUTS/ \
-v <path to license.txt>:/extra/freesurfer/license.txt \
--user $(id -u):$(id -g) \
justinblaber/synb0_25iso
```
For singularity:
```
singularity run -e \
-B INPUTS/:/INPUTS \
-B OUTPUTS/:/OUTPUTS \
-B <path to license.txt>:/extra/freesurfer/license.txt \
shub://justinblaber/synb0_25iso_app

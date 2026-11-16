"""Developer import helper; shipped project includes the resulting assets.
Run only with the verified Kenney archives extracted beside this repository.
"""
from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[1]
choices={
 'nature': ('kenney-nature-kit','Models/GLTF format',['tree_pineDefaultA','tree_pineTallA','tree_pineSmallA','rock_largeA','rock_largeB','rock_smallA','log_stack','grass','plant_bush']),
 'survival': ('kenney-survival-kit','Models/GLB format',['tent','tent-canvas','bedroll','bedroll-packed','bottle','bottle-large','campfire-pit','campfire-stand','workbench','box','box-open','chest','resource-wood','tree-log','signpost','signpost-single'])
}
for kind,(folder,models,names) in choices.items():
 src=ROOT.parent/folder
 dst=ROOT/'fieldlab/assets'/kind; dst.mkdir(parents=True,exist_ok=True)
 shutil.copy2(src/'License.txt',ROOT/'licenses'/f'Kenney-{kind}-CC0.txt')
 textures=src/models/'Textures'
 if textures.exists(): shutil.copytree(textures,dst/'Textures',dirs_exist_ok=True)
 for name in names:
  path=src/models/(name+'.glb')
  if path.exists(): shutil.copy2(path,dst/path.name)
 for name in ['bottle','box','bedroll-packed','resource-wood']:
  path=src/'Previews'/(name+'.png')
  if path.exists(): shutil.copy2(path,dst/path.name)

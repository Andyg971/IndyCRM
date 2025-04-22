from PIL import Image, ImageDraw
import os

# Dimensions de l'image
width, height = 500, 500
logo_size = 300

# Créer une image avec fond transparent
image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
draw = ImageDraw.Draw(image)

# Couleur violette du logo
purple_color = (142, 82, 232, 255)  # RGB + Alpha
light_purple = (182, 142, 232, 200)  # RGB + Alpha

# Dessiner un cercle pour la tête
head_radius = logo_size // 4
head_center = (width // 2, height // 2 - head_radius)
draw.ellipse(
    [
        head_center[0] - head_radius, 
        head_center[1] - head_radius,
        head_center[0] + head_radius, 
        head_center[1] + head_radius
    ], 
    fill=purple_color
)

# Dessiner un rectangle arrondi pour la carte
card_width = logo_size * 0.7
card_height = logo_size * 0.4
card_left = (width - card_width) / 2
card_top = height // 2 + head_radius * 0.2
draw.rectangle(
    [card_left, card_top, card_left + card_width, card_top + card_height],
    fill=purple_color,
    width=0
)

# Dessiner un petit rectangle pour le détail de la carte
detail_width = card_width * 0.2
detail_height = card_height * 0.25
detail_left = card_left + card_width * 0.1
detail_top = card_top + card_height * 0.25
draw.rectangle(
    [detail_left, detail_top, detail_left + detail_width, detail_top + detail_height],
    fill=light_purple,
    width=0
)

# Sauvegarder l'image
asset_dir = "IndyCrm/Assets.xcassets/IndyLogo.imageset"
if not os.path.exists(asset_dir):
    os.makedirs(asset_dir)

image.save(os.path.join(asset_dir, "IndyLogo.png"))
print(f"Logo créé et sauvegardé dans {asset_dir}/IndyLogo.png") 
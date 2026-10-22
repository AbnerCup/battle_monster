# Polices asiatiques

Fusion Poke Pixel Font, version 2026.09.01, remplace Power Green pour le coreen,
le japonais et le chinois simplifie. Seule la variante Small est utilisee,
avec les licences du projet et de ses sources.

Source : https://github.com/pixel-font-studio/fusion-poke-pixel-font

Les autres langues conservent Power Green. Les noms asiatiques du menu des
langues utilisent aussi Fusion avant meme de choisir une langue asiatique.
Le dessin et la mesure du texte utilisent les memes reglages. Les polices ne
sont pas rechargees depuis le disque a chaque dessin.

Taille de reference mkxp-z : Small 25, quel que soit le style source. Les tailles
personnalisees gardent leur proportion. Verifier le rendu dans les HUD apres
traduction, notamment les descriptions longues.

Fermer completement puis relancer le jeu pour reindexer Fonts (pas F12 seul).
Distribuer les trois fichiers fusion-poke-pixel-small-*.ttf (ja, ko, zh_hans)
et FusionPokeLicenses. Les variantes Normal et Narrow ne sont plus utilisees.

Les polices ne traduisent pas le jeu. Il faut toujours compiler les catalogues
messages_korean_core/game.dat, messages_japanese_core/game.dat et
messages_chinese_core/game.dat avec le systeme de traduction existant.

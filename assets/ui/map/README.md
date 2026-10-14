# Map atlas art

Current asset: `snow_forest_atlas_v02.png`, edited with the built-in imagegen
tool from the original forest atlas at the user's request: a snowy region
with trees. Shared by the main map and regional overview. Original retained.

## Snow version final prompt

Use case: lighting-weather / precise-object-edit. Edit target: attached terrain atlas. Transform this jungle terrain into a snowy winter forest region for the same survival-horror game map. Preserve the exact orthographic directly-overhead view, overall irregular oval silhouette, transparent exterior, fine pre-rendered game-art detail, and narrow central north-south clearing. Replace tropical foliage and palms with numerous individual pine, spruce and fir trees, their branches visibly coated with snow. Cover the ground and rocks with blue-grey white snow, including the central clearing. Make snow clearly visible throughout, interspersed with dark evergreen trees; cold moonlit atmosphere, desaturated slate blue shadows, restrained highlights (not pure brilliant white), PS1/PS2 survival horror visual style. Preserve alpha transparency around the terrain; no rectangular backdrop. No buildings, roads, rivers, grid, labels, icons, interface, text or markers. This is only the decorative substrate under an independently drawn live floor plan. Keep the same composition and top-down scale.

## Original forest

`forest_atlas_v01.png` is a transparent decorative terrain underlay generated
with the built-in imagegen tool on 2026-10-13. It is not navigable geometry.
Rooms, doors, markers, text, compass, scale and minimap are drawn live from
`AreaMap` by `ui/map_page.gd`. The same atlas is used in the main map and overview.

## Final prompt

Use case: stylized-concept. Asset type: transparent top-down terrain underlay for a PS1/PS2 survival-horror area-map screen. Create ONLY an irregular oval patch of dense dark jungle forest viewed exactly orthographically from directly above, canopy of many individual small trees with dark olive green foliage, subtle blue-grey rocky earth clearings and sparse tiny mossy boulders, fine handmade pre-rendered pixel-dithered texture, muted nighttime illumination. Composition: square canvas, irregular ragged forest silhouette occupying central 90 percent of image, transparent outside the silhouette. Center should have a subtle narrow north-south clearing of dark grey earth occupying about 18 percent of total width; surrounding forest rich in tiny leaf details. Low contrast but discernible canopy, colors near #0a171b, #1b302a and #425045. NO buildings, NO paths or roads, NO rivers, NO map grid, NO diagrams, NO labels, NO text, NO interface, NO borders, NO markers, NO orange, NO lights, NO perspective or horizon. This is a reusable decorative map substrate, not the navigable level geometry.

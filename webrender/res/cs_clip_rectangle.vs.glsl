#line 1
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

struct ClipRect {
    RectWithSize rect;
    vec4 mode;
};

ClipRect fetch_clip_rect(int index) {
    ClipRect cr;

    ivec2 uv = get_fetch_uv_2(index);

    vec4 rect = texelFetchOffset(sData32, uv, 0, ivec2(0, 0));
    cr.rect = RectWithSize(rect.xy, rect.zw);
    cr.mode = texelFetchOffset(sData32, uv, 0, ivec2(1, 0));

    return cr;
}

struct ClipCorner {
    RectWithSize rect;
    vec4 outer_inner_radius;
};

ClipCorner fetch_clip_corner(int index) {
    ClipCorner corner;

    ivec2 uv = get_fetch_uv_2(index);

    vec4 rect = texelFetchOffset(sData32, uv, 0, ivec2(0, 0));
    corner.rect = RectWithSize(rect.xy, rect.zw);
    corner.outer_inner_radius = texelFetchOffset(sData32, uv, 0, ivec2(1, 0));

    return corner;
}

struct ClipData {
    ClipRect rect;
    ClipCorner top_left;
    ClipCorner top_right;
    ClipCorner bottom_left;
    ClipCorner bottom_right;
};

ClipData fetch_clip(int index) {
    ClipData clip;

    clip.rect = fetch_clip_rect(index + 0);
    clip.top_left = fetch_clip_corner(index + 1);
    clip.top_right = fetch_clip_corner(index + 2);
    clip.bottom_left = fetch_clip_corner(index + 3);
    clip.bottom_right = fetch_clip_corner(index + 4);

    return clip;
}

void main(void) {
    CacheClipInstance cci = fetch_clip_item(gl_InstanceID);
    ClipArea area = fetch_clip_area(cci.render_task_index);
    Layer layer = fetch_layer(cci.layer_index);
    ClipData clip = fetch_clip(cci.data_index);
    RectWithSize local_rect = clip.rect.rect;

    ClipVertexInfo vi = write_clip_tile_vertex(local_rect,
                                               layer,
                                               area,
                                               cci.segment_index);
    vLocalRect = vi.clipped_local_rect;
    vPos = vi.local_pos;

    vClipMode = clip.rect.mode.x;
    vClipRect = vec4(local_rect.p0, local_rect.p0 + local_rect.size);
    vClipRadius = vec4(clip.top_left.outer_inner_radius.x,
                       clip.top_right.outer_inner_radius.x,
                       clip.bottom_right.outer_inner_radius.x,
                       clip.bottom_left.outer_inner_radius.x);
}

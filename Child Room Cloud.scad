model_height = [ 0.8, 5 ];
sun_height = 1.8;
merge_sun_height = 0.4;
hidden_screws_depth = model_height[0] / 2;
hidden_screws_hat_thickness = 2.3;
hidden_screws_hat_diameter = 8;
hidden_screws_diameter = 4;
hidden_screws_anchor_diameter = (10 * 2) + 7;
hidden_screws_visible_diameter = 14;
hidden_screws_ports_distance = [ 27, 27 ];
hidden_screws_offset_y = [ 2, -4 ];
model_port_depth = 4.0;

printer_margin_xy = 0.15;
printer_margin_z = 0.2;

cloud_frame_thickness = 3;
network_port_wall_thickness = 4;
cloud_inner_frame_depth = 2.4;

wall_thickness = 8.0;
$fn = $preview ? 20 : 100;
wall_screw_radius = 4;
mold_depth = 0.8;
mold_width = 3;
mold_extra_depth = 0.2;
backplate_cutout_distance = 1.5;
print_moon = true;
moon_radius = 10.0;
moon_circle_offset = 1.0;
moon_how_much = -0.45;
moon_thickness = [ 0.2, 0.2, 0.4 ]; // on, off, on...
sun_rays_count = 15;
sun_ray_overlap = 0.5;
sun_scale = 2.2;

hang_lock_screw_diameter = 0; // TODO
hang_screw_holes_offset = [-63, 15];
hang_screw_offset_y = 20;

network_screw_radius = 3.3 / 2; // Actual: 2.9mm
network_square_margin = [ 1.2, 6.6 ];
network_front_size = [ 19.1, 35.45 ];
network_square_size = [ 16.75, 22.4 ]; //[for (i = [0:1]) network_front_size[i] - network_square_margin[i] * 2];
network_screw_margin_y = 1.6;
network_screw_offset_y = network_front_size[1] / 2 - network_screw_margin_y - network_screw_radius;

network_square_nut_diameter = 5.4 + 0.3;
network_square_nut_slide_angle = 30;
network_square_nut_depth = 2.3; // 2.3 + 0.3 for previous print
network_square_nut_offset_z = [ 2.5, 2.5 ];

network_port_offset = [ -27, 24 ];
network_port_offset_per_port = 21;

network_ports_count = 4;

network_ports_width = network_port_offset_per_port * (network_ports_count - 1);

// The model to show
which = 0;

assert([for (i = hidden_screws_ports_distance) if (i < (hidden_screws_anchor_diameter + network_square_size[0]) / 2)
           true] == [],
       "Not enough room for expander in the wall");

function SubSum(x = 0, Index = 0) = x[Index] + ((Index <= 0) ? 0 : SubSum(x = x, Index = Index - 1));
// Sum the elements of a list.
function Sum(x) = SubSum(x = x, Index = len(x) - 1);

total_model_height = Sum(model_height);

module create_screw_hole(screw_hat_radius, screw_radius, screw_hat_angle, screw_hat_distance, screw_distance)
{
    screw_scale = screw_radius / screw_hat_radius;
    screw_angled_height = tan(screw_hat_angle) * (screw_hat_radius - screw_radius);
    if (screw_angled_height > 0)
    {
        linear_extrude(screw_angled_height, scale = screw_scale) circle(r = screw_hat_radius);
    }
    translate([ 0, 0, screw_angled_height ]) linear_extrude(screw_distance) circle(r = screw_radius);
    translate([ 0, 0, -screw_hat_distance ]) linear_extrude(screw_hat_distance) circle(r = screw_hat_radius);
}

function cloud_find_most(parts, left, i = 0, leftmost = 0) =
    i >= len(parts)
        ? parts[leftmost]
        : cloud_find_most(parts, left, i + 1,
                          (parts[i][0] - parts[i][2] < parts[leftmost][0] - parts[leftmost][2]) == left ? i : leftmost);

module cloud_from(parts, flat_bottom=true)
{
    union()
    {
        for (i = parts)
        {
            assert(len(i) == 3, "Invalid cloud part");
            translate([ i[0], i[1] + i[2], 0 ]) circle(r = i[2]);
        }
        polygon([for (p = parts) [p[0], p[1] + p[2]]]);
        if (flat_bottom)
        {
            leftmost = cloud_find_most(parts, true);
            rightmost = cloud_find_most(parts, false);
            polygon(
                [[leftmost [0], 0], [leftmost [0], leftmost [2]], [rightmost [0], rightmost [2]], [rightmost [0], 0], ]);
        }
    }
}

module create_cloud()
{
    if (network_ports_count == 4)
    {
        cloud_from([
            [ -10, 0, 20 ],
            [ -19, 27, 25 ],
            [ -40, 0, 25 ],
            [ 10, 25, 20 ],
            [ 35, 11, 20 ],
            [ 55, 0, 20 ],
        ]);
    }
    else if (network_ports_count == 1)
    {
        translate([ -10, 2, 0 ])
        {
            cloud_from([
                [ -12, -2, 15],
                [ -16, 16, 20 ],
                [ -40, 15, 14 ],
                [ -55, 2, 18 ],
                [-30, -3, 18],
                [ 26, 5, 15 ],
                [ 8, 2, 14 ],
                [ 16, 22, 11 ],
                [ 5, 29, 11 ],
            ], flat_bottom=false);
        }
    }
    else
    {
        assert(false, "Only 1 or 4 network ports are mapped");
    }
}

module create_sun_beam()
{
    rounding = 0.3;
    offset(r = rounding) offset(delta = -rounding) offset(r = -rounding) offset(delta = rounding) polygon([
        [ -1, 0 ],
        [ -2.5, 1 ],
        [ -1, 2 ],
        [ -2, 3 ],
        [ -0.5, 4 ],
        [ -1, 5 ],
        [ 0, 6 ],
        [ 0, 5 ],
        [ 0.5, 4 ],
        [ 0, 3 ],
        [ 1, 2 ],
        [ 0, 1 ],
        [ 2, 0 ],
        [ 1.5, 0 ],
    ]);
}

// network_screw_offset = [for (i = network_distance_between_square_and_screw_edge) network_square_height / 2 + i +
// network_screw_radius];

module create_network_cutout()
{
    union()
    {
        square(network_square_size + [ printer_margin_xy, printer_margin_xy ] * 2, center = true);

        translate([ 0, network_screw_offset_y, 0 ]) circle(r = network_screw_radius);
        translate([ 0, -network_screw_offset_y, 0 ]) circle(r = network_screw_radius);
    }
}

function hexagon_distance(d) = (d / 2) / cos(360 / 12);

function n_agon(sides, offset, d) =
    let(step = 360 / sides,
        r = hexagon_distance(d))[for (i = [1:sides])[sin(step * i + offset) * r, cos(step *i + offset) * r]];

function hexagon(nut_diameter, offset = 30) = n_agon(sides = 6, offset = offset, d = nut_diameter);

module hexagon_screw(nut_diameter, screw_diameter, nut_depth, screw_depth, offset = 30)
{
    r = hexagon_distance(nut_diameter);
    pol = hexagon(nut_diameter = nut_diameter, offset = 30);
    linear_extrude(nut_depth) polygon(pol);
    rotate(offset - 30) translate([ 0, 0, nut_depth ])
    {
        smaller_pol = [for (i = [ 1, 2, 4, 5 ]) pol[i]];
        linear_extrude(printer_margin_z) polygon(smaller_pol);
        square_side = min([for (p = smaller_pol) min(abs(p.x), abs(p.y))]) * 2;
        translate([ 0, 0, printer_margin_z ])
        {
            # linear_extrude(printer_margin_z) square(square_side, center = true);
            translate([ 0, 0, printer_margin_z ]) linear_extrude(screw_depth) circle(d = screw_diameter);
        }
    }
}

module create_network_backplate_cutout()
{
    union()
    {
        square(network_square_size, center = true);

        // translate([0, network_screw_offset_y, 0]) hexagon(d = 6);
        // translate([0, -network_screw_offset_y, 0]) hexagon(d = 6);
    }
}

module per_network_port()
{
    for (i = [1:network_ports_count])
    {
        translate([ (i - 1) * network_port_offset_per_port + network_port_offset[0], network_port_offset[1], 0 ])
            children();
    }
}

module create_network_ports()
{
    per_network_port() create_network_cutout();
}

hidden_screw_holes_offsets = [for (i = [0:1]) let(
    offset_sign =
        1 +
        2 * (i - 1))[hidden_screws_ports_distance[i] * offset_sign + i * network_ports_width + network_port_offset[0],
                     hidden_screws_offset_y[i] + network_port_offset[1]]];
echo(hidden_screw_holes_offsets);

module hang_on_screw_hole(r_max, r_min, height) {
    union() {
        circle(r = r_max);
        translate([0, height, 0]) circle(r = r_min);
        # translate([-r_min, 0, 0]) square(size = [r_min * 2, height], center = false);
    }
}

module teardrop_hole(r, angle) {
    union() {
        circle(r = r);
        x = sin(angle) * r;
        y = cos(angle) * r;
        t_y = y + x * tan(angle);
        # polygon([
            [x, y],
            [-x, y],
            [0, t_y],
        ]);
    }
}

// 3D
module create_hidden_screw_holes()
{
    assert(hidden_screws_hat_thickness + hidden_screws_depth + 0.6 < total_model_height, "The screw doesn't fit");
    for (offset = hidden_screw_holes_offsets)
    {
        translate(concat(offset, [cloud_inner_frame_depth + model_height[0]]))
        {
            # create_screw_hole(hidden_screws_hat_diameter / 2, hidden_screws_diameter / 2, 0,
                              hidden_screws_hat_thickness, 50);
            if ($preview)
            {
                # circle(d = hidden_screws_anchor_diameter);
                # circle(d = hidden_screws_visible_diameter);
            }
        }
    }
}

// 2D
module create_hidden_screw_holes_hardening()
{
    for (offset = hidden_screw_holes_offsets)
    {
        translate(offset) circle(d = hidden_screws_hat_diameter);
    }
}

module create_hollow_circle(r, hollow = 0)
{
    difference()
    {
        circle(r = r);
        if (hollow != 0)
        {
            circle(r = hollow);
        }
    }
}

wall_cutout_hole_distance = 12;

module create_wall_cutout(r = 5, hollow = 0, include_inner = true)
{
    hole_distance = wall_cutout_hole_distance;
    cut_distance = 6;
    height_offset = network_front_size[1] / 2;
    translate([ network_port_offset[0], network_port_offset[1], 0 ]) polygon([
        [ -hole_distance, -r ],
        [ -hole_distance, r ],
        [ -cut_distance, height_offset ],
        [ network_ports_width + cut_distance, height_offset ],
        [ network_ports_width + hole_distance, r ],
        [ network_ports_width + hole_distance, -r ],
        [ network_ports_width + cut_distance, -height_offset ],
        [ -cut_distance, -height_offset ],
    ]);
    /*per_network_port() {
        translate([-5, 10, 0]) create_hollow_circle(r = r, hollow = hollow);
        translate([-5, -10, 0]) create_hollow_circle(r = r, hollow = hollow);

        if (include_inner) {
            translate([-5, 0, 0]) create_hollow_circle(r = r, hollow = hollow);
            translate([5, 0, 0]) create_hollow_circle(r = r, hollow = hollow);
        }

        translate([0, -16, 0]) create_hollow_circle(r = r, hollow = hollow);
        translate([0, 16, 0]) create_hollow_circle(r = r, hollow = hollow);

        translate([5, -10, 0]) create_hollow_circle(r = r, hollow = hollow);
        translate([5, 10, 0]) create_hollow_circle(r = r, hollow = hollow);
    }
    */
    // create_wall_fastener(r = r, hollow = hollow);
}

module create_wall_fastener(r = 5, hollow = 0)
{
    hole_distance = wall_cutout_hole_distance;
    translate([ network_port_offset[0], network_port_offset[1], 0 ])
    {
        translate([ -hole_distance, 0, 0 ]) create_hollow_circle(r = r, hollow = hollow);
        translate([ network_ports_width + hole_distance, 0, 0 ]) create_hollow_circle(r = r, hollow = hollow);
    }
}

module create_wall_fastener_screws()
{
    hat_offset = 2;
    translate([ network_port_offset[0], network_port_offset[1], 0 ])
    {
        translate([ -10, 0, 3 ]) rotate([ 0, -73, 0 ]) translate([ 0, 0, hat_offset ])
            create_screw_hole(2.5, 1.5, 0, 100, 100);
        translate([ network_ports_width + 10, 0, 3 ]) rotate([ 0, 73, 0 ]) translate([ 0, 0, hat_offset ])
            create_screw_hole(2.5, 1.5, 0, 100, 100);
    }
}

module create_network_backplate()
{
    per_network_port() create_network_backplate_cutout();
}

module create_moon_cutout(remove)
{
    union()
    {
        translate([ moon_radius / 2 * sign(remove), 0, 0 ]) square([ moon_radius, 2 * moon_radius ], true);
        translate([ sign(remove) * moon_circle_offset, 0, 0 ]) scale([ abs(remove), 1, 1 ]) circle(moon_radius);
    }
}

module create_moon(remove)
{
    difference()
    {
        circle(moon_radius);
        if (remove != 0)
        {
            create_moon_cutout(remove);
        }
    }
}

module create_sun()
{
    count = sun_rays_count;
    for (i = [0:count])
    {
        rotate([ 0, 0, (i / count) * 360 ]) translate([ 0, moon_radius - sun_ray_overlap, 0 ]) create_sun_beam();
    }
    create_moon(0);
}

module sun_positioned()
{
    translate([ 35, 53, 0 ]) scale([ sun_scale, sun_scale, 1 ]) children();
}

module create_cloud_inner()
{
    offset(r = -cloud_frame_thickness) create_cloud();
}

// 2D representation of the frame of the inner cloud
module cloud_inner_frame()
{
    difference()
    {
        difference()
        {
            create_cloud_inner();
            create_network_ports();
        }
        difference()
        {
            offset(r = -cloud_frame_thickness) create_cloud_inner();
            offset(r = network_port_wall_thickness)
            {
                create_network_ports();
                # per_network_port() {
                    for (i = [-1:2:1])
                    {
                        translate([ 0, network_screw_offset_y * i, 0 ])
                            polygon(hexagon(nut_diameter = network_square_nut_diameter));
                    }
                }
            }
        }
    }
}

module create_cloud_frame()
{
    difference()
    {
        create_cloud();
        offset(r = printer_margin_xy) create_cloud_inner();
    }
}

module moon_layers(print, moon_thickness)
{
    if (len(moon_thickness) > 0)
    {
        if (print)
        {
            linear_extrude(moon_thickness[0]) create_moon(moon_how_much);
        }
        if (len(moon_thickness) > 1)
        {
            translate([ 0, 0, moon_thickness[0] ])
                moon_layers(!print, [for (i = [1:len(moon_thickness) - 1]) moon_thickness[i]]);
        }
    }
}

module positioned_moon()
{
    if (print_moon)
    {
        translate([ 0, 0, model_height[0] + model_height[1] - sun_height ]) sun_positioned()
        {
            moon_layers(true, moon_thickness);
        }
        translate([ 0, 0, model_height[0] + model_height[1] - sun_height ]) intersection()
        {
            sun_positioned() moon_layers(false, moon_thickness);
            linear_extrude(Sum(moon_thickness)) create_cloud_inner();
        }
    }
}

// 3D sun material at the final position
module create_sun_material(margin = 0, margin_z = 0)
{
    translate([ 0, 0, model_height[0] + model_height[1] - sun_height - margin_z ])
    {
        linear_extrude(sun_height - merge_sun_height + margin_z) difference()
        {
            offset(r = margin) sun_positioned() create_sun();
            create_cloud_inner();
        }
        translate([ 0, 0, sun_height - merge_sun_height + margin_z ]) linear_extrude(merge_sun_height)
            offset(r = margin) sun_positioned() create_sun();
    }
}

module create_network_ports_3d()
{
    per_network_port()
    {
        for (i = [0:1])
        {
            translate([
                0, (i * network_screw_offset_y) - ((1 - i) * network_screw_offset_y),
                model_height[0] + model_height[1]
            ]) rotate([ 0, 180, 0 ])
                hexagon_screw(nut_diameter = network_square_nut_diameter, nut_depth = network_square_nut_depth,
                              screw_diameter = network_screw_radius, screw_depth = model_height);
        }
        linear_extrude(total_model_height) create_network_cutout();
    }
}

module create_union(layer)
{
    layer_height = model_height[layer];
    offset = [ 0, 0, layer == 0 ? 0 : model_height[0] ];
    translate([ 0, 0, layer == 0 ? -printer_margin_z : 0 ]) difference()
    {
        union()
        {
            translate(offset)
            {
                difference()
                {
                    union()
                    {
                        cloud_base_depth = layer_height - (layer == 1 ? cloud_inner_frame_depth : 0);
                        if (layer == 0)
                        {
                            linear_extrude(layer_height) create_cloud();
                        }
                        else if (layer == 1)
                        {
                            linear_extrude(cloud_inner_frame_depth) cloud_inner_frame();
                            translate([ 0, 0, cloud_inner_frame_depth ]) linear_extrude(cloud_base_depth)
                                create_cloud_inner();
                        }
                    }
                    // # linear_extrude(layer_height) create_network_ports();
                }
                if (layer == 0)
                {
                    difference()
                    {
                        translate([ 0, 0, layer_height ]) linear_extrude(model_height[1] + printer_margin_z)
                            create_cloud_frame();
                        if (network_ports_count == 4)
                        {
#translate([ 0, 0, printer_margin_z ]) create_sun_material(printer_margin_xy, printer_margin_z);
                        }
                    }
                }
            }
            if (network_ports_count == 4 && layer == 1)
            {
                difference()
                {
                    create_sun_material();
                    linear_extrude(50) create_cloud_inner();
                }
            }
        }
        create_hidden_screw_holes();
        create_network_ports_3d();
    }
}

module create_unibody()
{
    difference() {
        linear_extrude(total_model_height) difference() {
            create_cloud();
            create_network_ports();
        }
        wall_thickness = (total_model_height - hidden_screws_hat_thickness) / 2;
        slide_length = hidden_screws_hat_diameter;

        translate([0, 0, total_model_height-hidden_screws_hat_thickness-wall_thickness]) for (offset = hang_screw_holes_offset) {
            translate([offset, hang_screw_offset_y, 0]) {
                translate([0, 0, hidden_screws_hat_thickness]) linear_extrude(wall_thickness) hang_on_screw_hole(r_max = hidden_screws_hat_diameter/2, r_min=hidden_screws_diameter/2, height=slide_length);
                linear_extrude(hidden_screws_hat_thickness) hang_on_screw_hole(r_max = hidden_screws_hat_diameter/2, r_min = hidden_screws_hat_diameter/2, height = slide_length);
                translate([0, slide_length, -(total_model_height-hidden_screws_hat_thickness-wall_thickness)])if ($preview)
                {
                    # circle(d = hidden_screws_anchor_diameter);
                    # circle(d = hidden_screws_visible_diameter);
                }
            }
        }
        if (hang_lock_screw_diameter > 0)
        {
            min_offset = min(hang_screw_holes_offset);
            max_offset = max(hang_screw_holes_offset);
            echo(min_offset, max_offset);
            for (part = [[min_offset, 180], [max_offset, 0]]) {
                translate([part[0], slide_length + hang_screw_offset_y - hidden_screws_diameter, total_model_height/2]) rotate([0, 0, part[1]]) # rotate([0, 90, 0]) rotate([0, 0, -90]) translate([0, 0, -hidden_screws_hat_diameter/2]) linear_extrude(200) teardrop_hole(r = hang_lock_screw_diameter/2, angle = 30);
            }
        }
        if ($preview) {
            # per_network_port() translate([0, slide_length/2, 0]) square(network_square_size + [0, slide_length], center = true);
        }
        create_network_ports_3d();
    }
}

module create_template_frame()
{
    rounding = 3;
    offset(r = rounding) offset(delta = -rounding) offset(r = -rounding) offset(delta = rounding) difference()
    {
        polygon([
            [ -35, 10 ],
            [ -48, 24 ],
            [ -35, 38 ],
            [ 42, 38 ],
            [ 52, 24 ],
            [ 42, 10 ],
        ]);
        polygon([
            [ -32, 16 ],
            [ -39, 24 ],
            [ -32, 32 ],
            [ 38, 32 ],
            [ 43, 24 ],
            [ 38, 16 ],
        ]);
    }
}

if (which == 0)
{
    echo("Cover");
    create_union(0);
}
else if (which == 1)
{
    echo("Base");
    create_union(1);
}
else if (which == 2)
{
    echo("Sun material modifier");
    difference()
    {
        create_sun_material();
        positioned_moon();
    }
}
else if (which == 3)
{
    echo("Moon") positioned_moon();
}
else if (which == 4)
{ // Only the cloud
    echo("Cloud only");
    cloud_inner_frame();
}
else if (which == 5)
{
    echo("Screw Reinforcement");
    // TODO: Add nuts?
    linear_extrude(total_model_height * 2) create_hidden_screw_holes_hardening();
}
else if (which == 6)
{
    echo("Unibody");
    create_unibody();
}
else if (which == 7)
{
    echo("Visual representation with attached network ports") difference()
    {
        create_cloud();
#per_network_port() {
        square(network_front_size, center = true);
    }
}
}
else if (which == 8)
{
    echo("Nut slide only") create_nut_slide(d = 2, angle = 20, depth = 0.6, length = -5);
}
else if (which == 9)
{
    echo("Visual representation of sun position") difference()
    {
        create_cloud();
        create_network_ports();
    }
#sun_positioned() create_sun();
}
else if (which == 10)
{
    echo("Cutout for margin checks");
    difference()
    {
        union()
        {
            create_union(0);
            create_union(1);
        }
        for (x = [-60:20:70])
        {
            for (y = [0:20:80])
            {
                translate([ x, y, -2 ]) linear_extrude(10) square(10, true);
            }
        }
    }
}
else if (which == 11)
{
    echo("Sun only");
    linear_extrude(sun_height) create_sun();
}
else if (which == 12)
{
    echo("Sun only moon modifier");
    positioned_moon(moon_how_much);
}
else if (which == 13) {
    linear_extrude(height = 5) hang_on_screw_hole(r_max = 8, r_min = 5, height = 12);
    translate([0, 0, 5])  linear_extrude(5) hang_on_screw_hole(r_max=8, r_min=8, height=12);
} else if (which == 14) {
    teardrop_hole(r = 5, angle = 30);
    translate([10, 0, 0]) teardrop_hole(r = 5, angle = 40);
    translate([20, 0, 0]) teardrop_hole(r = 5, angle = 60);
}

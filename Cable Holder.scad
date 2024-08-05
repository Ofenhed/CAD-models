rounding = 0.5;
thickness = 16.0;
corner_distance = 3.0;
$fn = $preview ? 20 : 100;
screw_radius = 1.90;
screw_hat_radius = 4.5;
screw_hat_angle = 45;
height = 12.0;
left_cable_radius = 2.0;
right_cable_radius = 2.0;
left_cable_tightening = 0.2;
right_cable_tightening = 0.2;
screw_margin = 0.8;
wall_thickness = 2.0;
corner = true;

function thickness() = corner ?
    sqrt(pow(max(right_cable_radius * 2 - right_cable_tightening, left_cable_radius * 2 - left_cable_tightening) + sqrt(pow(screw_hat_radius*2, 2)/2) + sqrt(pow(screw_radius + screw_margin, 2)/2), 2)*2)
    : max(right_cable_radius * 2 - right_cable_tightening, left_cable_radius * 2 - left_cable_tightening) + wall_thickness;

module outer() {
    if (corner) {
        polygon([
        [corner_distance, 0],
        [thickness(), 0],
        [0, thickness()],
        [0, corner_distance]
        ]);
    } else {
        width = screw_radius * 2 + screw_margin * 2 + left_cable_radius * 2 + right_cable_radius * 2 + wall_thickness;     
        outer_radius = right_cable_radius + wall_thickness;
        bounds = [
            [0, 0],
            [0, thickness()],
            [width - outer_radius, thickness()],
            [width, thickness()],
            [width, thickness() - outer_radius],
            [width, 0],
            ];
        union() {
            polygon(bounds, [[0, 1, 2, 4, 5]]);
            intersection() {
                polygon(bounds, [[0, 1, 3, 5]]);
                translate([width - outer_radius, thickness() - outer_radius, 0]) circle(outer_radius);
            }
        }
    }
}

module flat_cutout(radius, tighten) {
    union() {
        polygon([
            [-radius, -0],
            [-radius, radius - tighten],
            [radius, radius - tighten],
            [radius, 0],
        ]);
        translate([0, radius - tighten, 0]) circle(radius);
    }
}

module corner_cable_cutout(radius, tighten, t_x, t_y) {
    assert(t_x * t_y == 0 && t_x + t_y == 1, "t_x and t_y must be one of (1, 0) or (0, 1)");
    screw_offset = sqrt(pow(screw_radius + screw_margin, 2)*2);
    tight_radius = radius - tighten;
    required_height = tight_radius + sqrt(pow(radius, 2)*2);
    distance = required_height + screw_offset;
    polygon([
        [t_x * (distance - radius), t_y * (distance - radius)],
        [t_x * (distance - radius) + t_y * tight_radius, t_y * (distance - radius) + t_x * tight_radius],
        [t_x * (distance + radius) + t_y * tight_radius, t_y * (distance + radius) + t_x * tight_radius],
        [t_x * (distance + radius), t_y * (distance + radius)],
    ]);
    translate([t_x * distance + t_y * tight_radius, t_y * distance + t_x * tight_radius, 0]) circle(radius);
}

module screw() {
    screw_scale = screw_radius/screw_hat_radius;
    screw_angled_height = tan(screw_hat_angle)*(screw_hat_radius-screw_radius);
    linear_extrude(screw_angled_height, scale = screw_scale) circle(r = screw_hat_radius);
    translate([0, 0, screw_angled_height]) linear_extrude(thickness()) circle(r = screw_radius);
}

module merged() {
    difference() {
        linear_extrude(height) offset(r = rounding) offset(delta = -rounding) difference() {
           outer();
            if (corner) {
                corner_cable_cutout(left_cable_radius, left_cable_tightening, 1, 0);
                corner_cable_cutout(right_cable_radius, right_cable_tightening, 0, 1);
            } else {
                translate([left_cable_radius, 0, 0]) {
                    flat_cutout(left_cable_radius, left_cable_tightening);
                    translate([screw_radius * 2 + screw_margin * 2 + left_cable_radius + right_cable_radius, 0, 0]) flat_cutout(right_cable_radius, right_cable_tightening);
                }
            }
        }
        if (corner) {
            translate([thickness()/2, thickness()/2, height / 2]) rotate([90, 0, -45]) screw();
        } else {
            translate([left_cable_radius * 2 + screw_margin + screw_radius, thickness(), height / 2]) rotate([90, 0, 0]) screw();
        }
    }
}

//screw();

merged();
//flat_cutout(left_cable_radius, left_cable_tightening);
//outer();
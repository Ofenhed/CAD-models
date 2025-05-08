arm_height = 10;
arm_thickness = 3;
arm_rounding = 0.5;
arm_cutout_rounding = 2;
arm_thickness_around_screw = 3;
hinge_cutout_depth = 12;
hinge_depth = 40;
min_door_angle = 40;
max_rotation = 160;
screw_diameter = 4;
nut_diameter = 5;
nut_depth = 3;
part_height = 60;
printer_margin_z = 0.2;
printer_margin_xy = 1;
margin_behind_part = 12;
base_cord_cutout_distance = 1;
cord_donut_diameter = 3;
base_cord_angle = 75;
cord_diameter = 2;
base_cutout_distance = 3;
show_arms = true;
arm_coords = [
  [0, 0],
  [-3, 15],
  [0, 30],
  [5, 35],
];
arm_donut_position = [0, 25];
arm_donut_diameter = 3;

top_donut_diameter = 5;

arm_cutout_precision = 50;

screw_hole_distance = 0;
screw_hole_distance_side = false;
screw_hole_distance_depth = 14;

$fn = $preview ? 16 : 92;

module round_2d(outer = 0, inner = 0) {
    offset(r = outer) offset(delta = -outer) offset(r = inner) offset(delta = inner) children();
}

module mirror_symmetric() {
    mirror([1, 0, 0]) children();
}

module also_mirror_symmetric() {
    children();
    mirror_symmetric() children();
}

module base() {
    angle_x = sin(min_door_angle/2)*hinge_depth;
    intersection() {
        polygon([
          [0, 0],
          [-angle_x, hinge_depth],
          [angle_x, hinge_depth],
        ]);
        difference() {
            circle(r = hinge_depth);
            circle(r = hinge_cutout_depth);
            arm_translate() circle(d = screw_diameter);
            also_mirror_symmetric() arm_translate() circle(d = screw_diameter);
        }
    }
}

module arm() {
    round_2d(outer = arm_rounding, inner = arm_rounding) {
        for (i = [0:len(arm_coords)-2]) {
            hull() {
                translate(arm_coords[i]) circle(d = arm_thickness);
                translate(arm_coords[i+1]) circle(d = arm_thickness);
            }
        }
    }
}

module with_arm_screw_hinge() {
    difference() {
        union() {
            circle(d = screw_diameter + arm_thickness_around_screw);
            children();
        };
        circle(d = screw_diameter);
    }
}

function side_wall_distance(r, d) =
    let (angle = min_door_angle / 2,
         edge_position = [-sin(angle) * r, cos(angle) * r],
         offset_position = [cos(angle) * d, sin(angle) / d])
      edge_position + offset_position;

module arm_translate() {
    distance = hinge_cutout_depth + screw_hole_distance_depth;
    angle = min_door_angle/2;
    position = screw_hole_distance_side ?
        side_wall_distance(distance, screw_hole_distance)
        : [screw_hole_distance, distance];
    translate(position) children();
}

module arm_cutout(precision = $fn) {
    step = max_rotation / arm_cutout_precision;
    offset(r = printer_margin_xy) with_arm_screw_hinge() round_2d(inner=arm_cutout_rounding) for (i = [0:arm_cutout_precision]) {
        rotate([0, 0, -step * i]) arm();
    }
}

module edges_visualizer() {
    edges_thickness = 10;
    rotate(min_door_angle/2) translate([-edges_thickness, 0, 0]) {
        square([edges_thickness, hinge_depth + edges_thickness], center = false);
        translate([0 + edges_thickness, hinge_depth]) square([margin_behind_part, edges_thickness]);
    }
}

module arm_cord_base() {
    //translate([0, hinge_cutout_depth+base_cord_cutout_distance, 0]) rotate([0, 0, base_cord_angle]) rotate([0, -90, 0]) linear_extrude(100) circle(d=cord_diameter);
    translate([0, hinge_cutout_depth+base_cord_cutout_distance, 0]) # rotate_extrude() translate([cord_donut_diameter, 0, 0]) circle(d=cord_diameter);
}

module arm_cord_arm() {
    translate(arm_donut_position) rotate_extrude() translate([arm_donut_diameter, 0, 0]) circle(d=cord_diameter);
}

function hexagon_distance(d) = (d / 2) / cos(360 / 12);

function n_agon(sides, offset, d) =
    let(step = 360 / sides,
        r = hexagon_distance(d))[for (i = [1:sides])[sin(step * i + offset) * r, cos(step *i + offset) * r]];

function hexagon(nut_diameter, offset = 30) = n_agon(sides = 6, offset = offset, d = nut_diameter);

module assembled() {
    time = $t <= 0.5 ? $t*2 : 1-($t - 0.5)*2;
    arm_cutout_height = arm_height + printer_margin_z * 2;
    base_layer_height = (part_height - arm_cutout_height*2) / 3;
    module base_layer() {
        linear_extrude(base_layer_height) base();
        translate([0, 0, base_layer_height]) children();
    }
    module arm_layer() {
        difference() {
            union() {
                linear_extrude(arm_cutout_height) difference() {
                    base();
                    arm_translate() arm_cutout();
                }
                if (show_arms) {
                    translate([0, 0, printer_margin_z]) arm_translate() difference() {
                        linear_extrude(arm_height) rotate([0, 0, -max_rotation * time]) with_arm_screw_hinge() arm();
                        translate([0, 0, arm_height/2]) arm_cord_arm();
                    }
                }
            }
            translate([0, 0, arm_cutout_height/2]) arm_cord_base();
        }
        translate([0, 0, arm_cutout_height]) children();
    }
    base_layer()
    arm_layer()
    base_layer()
    mirror_symmetric()
    arm_layer() difference() {
        base_layer();
        arm_translate() linear_extrude(nut_depth) polygon(hexagon(nut_diameter = nut_diameter));
        # translate([0, hinge_cutout_depth, base_layer_height]) rotate([0, 90, 0]) rotate_extrude() translate([top_donut_diameter, 0, 0]) circle(d=cord_diameter);
    }
}

module animated() {
    assembled() with_arm_screw_hinge() arm();
}

animated();
//arm_cord_base();
if ($preview) {
    # edges_visualizer();
}
//arm_translate() # arm();

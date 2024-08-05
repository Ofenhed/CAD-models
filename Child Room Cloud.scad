model_height = 2.0;
model_port_depth = 4.0;
which = 0;
wall_thickness = 20.0;
$fn = $preview ? 20 : 100;
wall_screw_radius = 4;

module create_screw_hole(screw_hat_radius, screw_radius, screw_hat_angle, screw_hat_distance, screw_distance) {
    screw_scale = screw_radius/screw_hat_radius;
    screw_angled_height = tan(screw_hat_angle)*(screw_hat_radius-screw_radius);
    if (screw_angled_height > 0) {
        linear_extrude(screw_angled_height, scale = screw_scale) circle(r = screw_hat_radius);
    }
    translate([0, 0, screw_angled_height])
        linear_extrude(screw_distance) circle(r = screw_radius);
    translate([0, 0, -screw_hat_distance]) linear_extrude(screw_hat_distance) circle(r = screw_hat_radius);
}

module create_cloud() {
    union() {
        translate([-40, 25, 0]) circle(25);
        translate([-12, 40, 0]) circle(25);
        //translate([0, 45, 0]) circle(10);
        translate([12.5, 50, 0]) circle(15);
        //translate([20, 30, 0]) circle(7);
        translate([-20, 15, 0]) square([45, 23]);
        translate([35, 30, 0]) circle(20);
        translate([55, 20, 0]) circle(20);
        translate([-40, 0, 0]) square([95, 15]);
    }
}

module create_cloud_screw_holes_bad() {
    translate([-55, 25, 0]) circle(r = wall_screw_radius);
    translate([65, 20, 0]) circle(r = wall_screw_radius);
}

module create_sun_beam() {
    polygon([
        [-1, 0],
        [-2.5, 1],
        [-1, 2],
        [-2, 3],
        [-0.5, 4],
        [-1, 5],
        [0, 6],
        [0, 5],
        [0.5, 4],
        [0, 3],
        [1, 2],
        [0, 1],
        [2, 0],
        [1.5, 0],
    ]);    
}

network_screw_radius = 3.5 / 2;
network_square_height = 22.5;
network_square_width = 17;
network_distance_between_square_and_screw_edge = 3;
network_screw_offset = network_square_height / 2 + network_distance_between_square_and_screw_edge + network_screw_radius;


module create_network_cutout() {
    // TODO: Verifiera med bättre skujtmått
    union() {
        square([network_square_width, network_square_height], center = true);
        
        translate([0, network_screw_offset, 0]) circle(r = network_screw_radius);
        translate([0, -network_screw_offset, 0]) circle(r = network_screw_radius);
    }
}

module hexagon(r, offset = 30) {
    step = 360 / 6;
    polygon(
        [for (i = [0:5]) [sin(step * i + offset) * r, cos(step * i + offset) * r]]
            );
        
}

module create_network_backplate_cutout() {
    union() {
        square([network_square_width, network_square_height], center = true);
        
        translate([0, network_screw_offset, 0]) hexagon(r = 5);
        translate([0, -network_screw_offset, 0]) hexagon(r = 5);

    }
    
}

network_port_offset_x = -29;
network_port_offset_y = 22;
network_port_offset_per_port = 21;
network_ports_count = 4;
    network_ports_width = network_port_offset_per_port * (network_ports_count - 1);

module per_network_port() {
    for (i = [1:network_ports_count]) {
        translate([(i-1) * network_port_offset_per_port + network_port_offset_x, network_port_offset_y, 0]) children();
    }
}

module create_network_ports() {
    per_network_port() create_network_cutout();
}

module create_wall_cutout() {
    per_network_port() {
        translate([-5, 10, 0]) circle(r = 10);
        translate([-5, 0, 0]) circle(r = 10);
        translate([-5, -10, 0]) circle(r = 10);
        translate([5, 0, 0]) circle(r = 10);
        translate([5, -10, 0]) circle(r = 10);
        translate([5, 10, 0]) circle(r = 10);
    }
}

module create_wall_fastener() {
    translate([network_port_offset_x, network_port_offset_y, 0]) {
        translate([-15, 0, 0]) circle(r = 10);
        translate([network_ports_width + 15, 0, 0]) circle(r = 10);
    }
}

module create_wall_fastener_screws() {
    translate([network_port_offset_x, network_port_offset_y, 0]) {
        translate([-10, 0, 3]) rotate([0, -73, 0]) translate([0, 0, 5]) create_screw_hole(2.5, 1.5, 0, 100, 100);
        translate([network_ports_width + 10, 0, 3]) rotate([0, 73, 0]) translate([0, 0, 5]) create_screw_hole(2.5, 1.5, 0, 100, 100);
    }
}

module create_network_backplate() {
    per_network_port() create_network_backplate_cutout();
}

module create_sun() {
    count = 15;
    for (i = [0:count]) {
        rotate([0, 0, (i / count) * 360]) translate([0, 9.5, 0]) create_sun_beam();    
    }
    circle(10);
    
}

module create_positioned_sun() {
    translate([35, 50, 0]) scale([1.5, 1.5, 1]) create_sun();
}

module create_sun_material() {
    linear_extrude(model_height) difference() {
        create_positioned_sun();
        create_cloud();
    }
}

module create_union() {
    difference() {
        union() {
            linear_extrude(model_height) {
                difference() {
                    union() {
                        create_cloud();
                        create_positioned_sun();
                    }
                    create_network_ports();
                }
            }
            translate([0, 0, model_height]) { 
                linear_extrude(model_port_depth) {
                    difference() {
                        create_wall_cutout();
                        create_network_backplate();
                    }
                }
                linear_extrude(wall_thickness - model_port_depth) {
                    difference() {
                        create_wall_fastener();
                        create_network_backplate();
                    }
                }
            }
        }
        create_wall_fastener_screws();
    }
}

if (which == 0) {
    create_union();
} else if (which == 1) {
    create_sun_material();
} else if (which == 2) {
    create_network_ports();
} else if (which == 3) {
    difference() {
        create_cloud();
        create_network_ports();
    }
    # create_positioned_sun();
} else if (which == 4) {
    create_cloud();
} else if (which == 5) {
    create_network_backplate_cutout();
}
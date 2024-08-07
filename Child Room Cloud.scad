model_height = 0.8;
model_port_depth = 4.0;
which = 0;
wall_thickness = 8.0;
$fn = $preview ? 20 : 100;
wall_screw_radius = 4;
mold_depth = 0.8;
mold_width = 3;
mold_extra_depth = 0.2;

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
        translate([-19, 42, 0]) circle(25);
        //translate([0, 45, 0]) circle(10);
        translate([10, 45, 0]) circle(20);
        //translate([20, 30, 0]) circle(7);
        translate([-20, 15, 0]) square([45, 23]);
        translate([35, 31, 0]) circle(20);
        translate([55, 20, 0]) circle(20);
        translate([-40, 0, 0]) square([95, 15]);
    }
}

module create_sun_beam() {
    rounding = 0.3;
    offset(r = rounding) offset(delta = -rounding) offset(r = -rounding) offset(delta = rounding) polygon([
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

network_screw_radius = 3.3 / 2;
network_square_margin = [1.2, 6.6];
network_front_size = [19.1, 35.45];
network_square_size = [for (i = [0:1]) network_front_size[i]-network_square_margin[i]*2];
network_screw_margin_y = 1.6;
network_screw_offset_y = network_front_size[1] / 2 - network_screw_margin_y - network_screw_radius;
//network_screw_offset = [for (i = network_distance_between_square_and_screw_edge) network_square_height / 2 + i + network_screw_radius];


module create_network_cutout() {
    union() {
        square(network_square_size, center = true);
        
        translate([0, network_screw_offset_y, 0]) circle(r = network_screw_radius);
        translate([0, -network_screw_offset_y, 0]) circle(r = network_screw_radius);
    }
}

module hexagon(d, offset = 30) {
    step = 360 / 6;
    r = (d / 2) / cos(step / 2);
    polygon(
        [for (i = [0:5]) [sin(step * i + offset) * r, cos(step * i + offset) * r]]
            );
        
}

module create_network_backplate_cutout() {
    union() {
        square(network_square_size, center = true);
        
        translate([0, network_screw_offset_y, 0]) hexagon(d = 6);
        translate([0, -network_screw_offset_y, 0]) hexagon(d = 6);

    }
    
}

network_port_offset_x = -32;
network_port_offset_y = 24;
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

module create_hollow_circle(r, hollow = 0) {
    difference() {
        circle(r = r);
        if (hollow != 0) {
            circle(r = hollow);
        }
    }
}

wall_cutout_hole_distance = 12;

module create_wall_cutout(r = 5, hollow = 0, include_inner = true) {
    hole_distance = wall_cutout_hole_distance;
    cut_distance = 6;
    height_offset = network_front_size[1]/2;
    translate([network_port_offset_x, network_port_offset_y, 0]) polygon([
        [-hole_distance, -r],
        [-hole_distance, r],
        [-cut_distance, height_offset],
        [network_ports_width + cut_distance, height_offset],
        [network_ports_width + hole_distance, r],
        [network_ports_width + hole_distance, -r],
        [network_ports_width + cut_distance, -height_offset],
        [-cut_distance, -height_offset],
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
    create_wall_fastener(r = r, hollow = hollow);
}

module create_wall_fastener(r = 5, hollow = 0) {
    hole_distance = wall_cutout_hole_distance;
    translate([network_port_offset_x, network_port_offset_y, 0]) {
        translate([-hole_distance, 0, 0]) create_hollow_circle(r = r, hollow = hollow);
        translate([network_ports_width + hole_distance, 0, 0]) create_hollow_circle(r = r, hollow = hollow);
    }
}

module create_wall_fastener_screws() {
    hat_offset = 2;
    translate([network_port_offset_x, network_port_offset_y, 0]) {
        translate([-10, 0, 3]) rotate([0, -73, 0]) translate([0, 0, hat_offset]) create_screw_hole(2.5, 1.5, 0, 100, 100);
        translate([network_ports_width + 10, 0, 3]) rotate([0, 73, 0]) translate([0, 0, hat_offset]) create_screw_hole(2.5, 1.5, 0, 100, 100);
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
    translate([35, 53, 0]) scale([1.5, 1.5, 1]) create_sun();
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
                translate([0, 0, model_port_depth]) linear_extrude(wall_thickness - model_port_depth) {
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

module create_template_frame() {
    rounding = 3;
    offset(r = rounding) offset(delta = -rounding) offset(r = -rounding) offset(delta = rounding) difference() {
            polygon([
                [-35, 10],
                [-48, 24],
                [-35, 38],
                [42, 38],
                [52, 24],
                [42, 10],
            ]);
            polygon([
                [-32, 16],
                [-39, 24],
                [-32, 32],
                [38, 32],
                [43, 24],
                [38, 16],
            ]);
            
        }
}


if (which == 0) { // Base
    create_union();
} else if (which == 1) { // Sun modifier
    create_sun_material();
} else if (which == 2) { 
    create_network_ports();
} else if (which == 3) {
    difference() {
        create_cloud();
        create_network_ports();
    }
    # create_positioned_sun();
} else if (which == 4) { // Only the cloud
    create_cloud();
} else if (which == 5) {
    create_network_backplate_cutout();
} else if (which == 6) { // Cutout mold
    linear_extrude(mold_depth) difference() {
        create_wall_cutout(r = 0.5);
        create_wall_fastener(r = 0.5);
        offset(delta = -mold_width) create_wall_cutout(r = 0.5);
    }
    translate([0, 0, mold_depth]) linear_extrude(mold_extra_depth) intersection() {
        create_wall_cutout(r = 0.5);
        difference() {
            create_wall_fastener(r = 5, hollow = 4.5);
            offset(delta = -mold_width) create_wall_cutout(r = 0.5);
        }
        /*difference() {
            create_wall_cutout(r = 5, hollow = 4.5, include_inner = false);
            create_wall_cutout(r = 2.5);
        }*/
    }
} else if (which == 7) { // How it looks with network ports attached
    difference() {
        create_cloud();
        # per_network_port() {
            square(network_front_size, center = true);
        }
    }
}
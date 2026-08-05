// ============================================================================
//  Raspberry Pi 3 Model B - wall-mount vented case
//
//  Screws flat to a plywood wall through four ears. The body of the case
//  stands off the wall on a set of fins, leaving a 20 mm air gap underneath.
//  The fins run across the short axis of the board, so when the case is
//  mounted with the long edge horizontal they form vertical chimneys:
//  cool air enters at the bottom, rises through the vented back plate,
//  over the board, and out of the open top.
//
//  Prints as one piece on a Creality Ender-3 V3 SE with NO supports.
//
//  Units: mm.  z = 0 is the face of the plywood.
// ============================================================================

$fa = 2;
$fs = 0.4;

/* ------------------------------- the board ------------------------------ */
pcb_x      = 85;    // Pi 3 B PCB length
pcb_y      = 56;    // Pi 3 B PCB width
hole_dx    = 58;    // mounting-hole pitch, long axis
hole_dy    = 49;    // mounting-hole pitch, short axis
hole_inset = 3.5;   // hole centre from the PCB corner

/* ------------------------------ fit / walls ----------------------------- */
fit   = 0.5;    // clearance around the PCB, per side
wall  = 2.4;    // tray wall thickness
end_t = 2.8;    // the two end walls of the standoff stage
fin_t = 2.4;    // internal air-channel fins

/* ------------------------- heights above the wall ----------------------- */
gap       = 20;   // air gap: plywood -> underside of the back plate
plate_t   = 3;    // vented back plate
boss_h    = 6;    // PCB standoff height above the plate
boss_d    = 6;
boss_hole = 2.2;  // self-tapping pilot hole for an M2.5 screw
tray_h    = 15;   // tray wall height above the back plate

/* ------------------------------ mount ears ------------------------------ */
ear_l    = 15;    // how far an ear sticks out sideways
ear_w    = 16;
ear_t    = 5;
ear_hole = 4.5;   // shank clearance for a #8 or M4 wood screw
ear_cs   = 9;     // countersink diameter

/* -------------------------------- vents --------------------------------- */
vent_d     = 6.5;
vent_pitch = 10.5;
vent_edge  = 7;    // margin from plate edge to the nearest vent centre
n_span     = 6;    // air channels across the back -> n_span-1 internal fins

/* ------------------------------- derived -------------------------------- */
tray_w = pcb_x + 2*fit + 2*wall;   // 90.8
tray_d = pcb_y + 2*fit + 2*wall;   // 61.8
px0    = wall + fit;               // PCB origin inside the tray
py0    = wall + fit;

z_plate = gap;                     // underside of the back plate
z_top   = gap + plate_t;           // top face of the back plate
z_pcb   = z_top + boss_h;          // underside of the PCB
z_rim   = z_top + tray_h;          // top of the tray walls

boss_pts = [ for (i = [0,1], j = [0,1])
             [px0 + hole_inset + i*hole_dx, py0 + hole_inset + j*hole_dy] ];

/* ============================== primitives ============================== */

// rounded rectangle, 2D, anchored at the origin
module rrect(w, d, r) {
    translate([r, r]) offset(r = r) square([w - 2*r, d - 2*r]);
}

// rounded rectangular window cut straight through the X axis
module xwindow(cx, cy, cz, wy, wz, r) {
    hull()
        for (dy = [-1, 1], dz = [-1, 1])
            translate([cx - 10, cy + dy*(wy/2 - r), cz + dz*(wz/2 - r)])
                rotate([0, 90, 0]) cylinder(h = 20, r = r);
}

// rounded vertical slot cut through the X axis
module xslot(x0, cy, xlen, z0, z1, w) {
    hull()
        for (z = [z0 + w/2, z1 - w/2])
            translate([x0, cy, z]) rotate([0, 90, 0]) cylinder(h = xlen, r = w/2);
}

// rounded vertical slot cut through the Y axis
module yslot(cx, y0, ylen, z0, z1, w) {
    hull()
        for (z = [z0 + w/2, z1 - w/2])
            translate([cx, y0, z]) rotate([-90, 0, 0]) cylinder(h = ylen, r = w/2);
}

/* =========================== standoff structure ========================== */

// Internal fin. Flared at the foot for bed adhesion, flared at the top so the
// back plate only has to bridge ~9 mm instead of the full channel width.
module fin(cx, t) {
    flare = 5.5;
    cap   = 8;
    difference() {
        union() {
            translate([cx - t/2, 0, 0]) cube([t, tray_d, gap]);
            hull() {                                      // foot
                translate([cx - flare/2, 0, 0])       cube([flare, tray_d, 0.01]);
                translate([cx - t/2, 0, 2.4])         cube([t, tray_d, 0.01]);
            }
            hull() {                                      // cap
                translate([cx - t/2, 0, gap - 3.2])    cube([t, tray_d, 0.01]);
                translate([cx - cap/2, 0, gap - 0.01]) cube([cap, tray_d, 0.01]);
            }
        }
        for (k = [1:2])
            xwindow(cx, tray_d * k / 3, gap/2, 14, 12, 3);
    }
}

// End wall. Also the anchor for the mount ears, so it keeps more material.
module end_wall(x0) {
    difference() {
        translate([x0, 0, 0]) cube([end_t, tray_d, gap]);
        for (k = [1:2])
            xwindow(x0 + end_t/2, tray_d * k / 3, gap/2, 14, 12, 3);
    }
}

/* ============================== mount ears =============================== */

// Two ears on the left-hand end; mirrored for the right.
module ear_pair() {
    for (cy = [ear_w/2 + 1, tray_d - ear_w/2 - 1]) {
        difference() {
            linear_extrude(ear_t)
                translate([-ear_l, cy - ear_w/2]) rrect(ear_l + 5, ear_w, 4);
            translate([-ear_l/2 - 1, cy, -1])
                cylinder(d = ear_hole, h = ear_t + 2);
            translate([-ear_l/2 - 1, cy, ear_t - (ear_cs - ear_hole)/2])
                cylinder(d1 = ear_hole, d2 = ear_cs,
                         h = (ear_cs - ear_hole)/2 + 0.01);
        }
        // 45-degree gusset tying the ear back into the end wall
        translate([0, cy + 1.2, 0]) rotate([90, 0, 0])
            linear_extrude(2.4)
                polygon([[-ear_l + 4, 0], [end_t, 0], [end_t, gap]]);
    }
}

/* ============================== back plate =============================== */

module back_plate() {
    translate([0, 0, z_plate]) linear_extrude(plate_t) rrect(tray_w, tray_d, 3);
}

module vent_grid() {
    nx = floor((tray_w - 2*vent_edge) / vent_pitch) + 1;
    ny = floor((tray_d - 2*vent_edge) / vent_pitch) + 1;
    sx = (tray_w - 2*vent_edge) / (nx - 1);
    sy = (tray_d - 2*vent_edge) / (ny - 1);
    for (i = [0 : nx - 1], j = [0 : ny - 1]) {
        x = vent_edge + i*sx;
        y = vent_edge + j*sy;
        if (min([for (p = boss_pts) norm([x, y] - p)]) > 8)
            translate([x, y, z_plate - 1])
                cylinder(d = vent_d, h = plate_t + 2);
    }
}

module bosses() {
    for (p = boss_pts)
        translate([p[0], p[1], z_top - 0.01])
            cylinder(d = boss_d, h = boss_h + 0.01);
}

module boss_holes() {
    for (p = boss_pts)
        translate([p[0], p[1], z_plate - 1])
            cylinder(d = boss_hole, h = plate_t + boss_h + 2);
}

/* ================================= tray ================================== */

module port_cuts() {
    zc = z_pcb - 0.5;          // start just under the PCB
    h  = z_rim - zc + 3;       // and run out through the open top

    // Ethernet + both USB stacks: the whole right-hand edge
    translate([tray_w - wall - 1, py0 + 1.5, zc]) cube([wall + 2, 52.5, h]);

    // micro-USB power, HDMI and the AV jack: bottom edge
    translate([px0 + 4, -1, zc]) cube([54, wall + 2, h]);

    // microSD card, which sits under the board: left edge
    translate([-1, py0 + 19, z_top + 3.5]) cube([wall + 2, 18, tray_h]);

    // notch for a GPIO ribbon cable: top edge
    translate([px0 + 4, tray_d - wall - 1, z_rim - 6]) cube([57, wall + 2, 8]);

    // extra vent slots in the wall that is left over on each edge
    for (cx = [69, 77, 85]) {
        yslot(cx, -1, wall + 2, z_top + 3, z_rim - 3, 4);
        yslot(cx, tray_d - wall - 1, wall + 2, z_top + 3, z_rim - 3, 4);
    }
    for (cy = [8, 15, 47, 54])
        xslot(-1, cy, wall + 2, z_top + 3, z_rim - 3, 4);
}

module tray_walls() {
    difference() {
        translate([0, 0, z_top]) linear_extrude(tray_h)
            difference() {
                rrect(tray_w, tray_d, 3);
                translate([wall, wall]) rrect(tray_w - 2*wall, tray_d - 2*wall, 1.5);
            }
        port_cuts();
    }
}

/* =============================== assembly ================================ */

module rpi3_wall_mount() {
    difference() {
        union() {
            end_wall(0);
            end_wall(tray_w - end_t);
            for (i = [1 : n_span - 1]) fin(tray_w * i / n_span, fin_t);
            back_plate();
            tray_walls();
            bosses();
            ear_pair();
            translate([tray_w, 0, 0]) mirror([1, 0, 0]) ear_pair();
        }
        vent_grid();
        boss_holes();
    }
}

rpi3_wall_mount();

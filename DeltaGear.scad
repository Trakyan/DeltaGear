include <_lib/gear_generator.scad>
include <_lib/fillet_generator.scad>
include <_lib/bolt_sizes.scad>
include <_lib/parts.scad>
include <_lib/math.scad>
include <_lib/colors.scad>

/*
AUTOCALIBRATION
    Silicone sock over hotend, so only the tip of the nozzle can complete the circuit. That way it's more garanteed to find the bed edge, if you don't get a rid within an expected amount of steps you know the silicone sock hit the bed and the nozzle is off the edge. If nessecary add a contact on the silicone sock so you know more percisely and for sure.
*/

pi=3.141592; //Go nuts. these are all I could remember off the top of my head

{//Specs 'n stuff
{//machine specs
    //dimensions of cylindrical build volume desired.
print_radius = 150/2;
print_height = 100;
base_diameter = print_radius/(1-1/sqrt(3)); //diameter of the base. its a renaulx(?) triangle. That triangle with the roundish sides. If you use this your build volume ends up being approx a triangular base pyramid with edges of this length. 
    
    //starting with 200mm square bed printer, each iteration from there can print 1) 315mm   2) 530mm      3) 920mm     4)1600mm
}
{//hardware
string_diameter = 1; 

hardware = M5;
    
pulley = hardware[3];
{// pulley  
pulley_bore = pulley[2];
pulley_radius = pulley[1];
pulley_thick = pulley[0]; 
}
bearing = hardware[3];
{// bearing
bearing_bore = bearing[2]; 
bearing_radius = bearing[1];
bearing_thick = bearing[0]; 
}
effector_bearing = bearing_608;//bearing;
{// bearing
effector_bearing_bore = effector_bearing[2]; 
effector_bearing_radius = effector_bearing[1];
effector_bearing_thick = effector_bearing[0]; 
}
nut = hardware[1];
{// nut
nut_thick = nut[0];
nut_radius = nut[1];
}

bolt = hardware[0];   
{// bolt
bolt_radius = bolt[0];
bolt_head_thick = bolt[2];
bolt_head_radius = bolt[1];
}
washer = hardware[2];//washer thickness
pulley_bolt = 80; //longer bolt => thicker arm
base_bolt = pulley_bolt; //how long the bolt is that secures the shoulder to the frame.

hotend_height = 70; //approximate. If unsure, use an overestimate.
bowden_radius = 2;
    
motor = NEMA17;
motor_width = motor[0];
motor_length = motor[1];
motor_shaft_radius = motor[4];
motor_shaft_length = motor[5];
motor_key = motor[6];
motor_key_length = motor[7];

}
{//misc

wall_thick = 5; //thickness for bezels around bearings, the shoulder plates, etc.
min_thick = 2; //mostly for things like spacers or parts used to register or locate two mating pieces. Not structural parts so they dont need to be as thick as 'wall thick'.
number_gear_spokes = 2; //keep it even, I'm checking (it makes the nut trap much easier to access).
chamfer_angle = 45; //sets how aggressive your chamfers (overhangs) are. Keep it at 45, I can't guarantee anything else working.
thread_angle = 45; //for threads on the effector
thread_pitch = 2;

string_clearance = 1; //how much clearance the string has when routed.
clearance = 5; //minimum spacing between two non contacting parts, whether they are static relative to each other or approach each other during operation. Can't be too big or some parts of the model wont exist. A couple of mm should be fine, this is just to give yourself some margin for error at the extreme ends of a component's movement.
    
tolerance = 0.2; //self explanatory, clearance between two parts that need to fit.
res = 3; //i.e. a new face is created every XX mm along the perimiter of a circle, or a new slice is made every XX mm vertically in an extrusion. I don't think this does anything at the moment, I'll have to fix that. WHOOP! Fixed it, it does something.
slices = 7; //dunno if this is good for anything though.... Nevermind, it does something, you can use this instead of res for things like how many slices make up an arc. Its stupid, doesn't scale well, use res instead. Done. Slices does nothing. 
    
    //think of these as the resolution for how 'efficient' your machine is. Some parameters are itteratively solved for, and this is the size of the increments. Anything will work, but smaller numbers get you closer to the 'ideal' solution.
angle_step = 2.5; //how much it increments the angle each time it checks for a collision. If you want to squeeze every last bit of efficiency out of the machine, make this small (and watch your computer die a horrible death).
spacing_step = 2.5; //ditto, but checks how much spacing to add.
reach_step = 2.5; //ditto, but checks by how much to increment the arm's reach when current reach is insufficient (for build volumes with more extreme proportions).
}
{//gear settings
    gear_helix = 2; //single or double helix. Keep it as a double helix, just leave it at that.
    gear_teeth = 15; //number of teeth used to make the gear for the joint, half the teeth are cut off. Keep it an odd number because I said so, I'll be checking. Makes constructing the model simpler and decreases render time(!!!).
    gear_twist = gear_teeth/4%1; //the number of teeth the helix goes across. The larger the number, the the smoother the transition from one gear to the next, in theory. Keep it reasonable.
    pressure_angle = 30; //pressure angle for extruder gears, drive gears, etc... those connected to the motor
    reel_teeth = 20; //more teeth->smaller teeth->smoother mesh(+)->easier to strip(-)
}
{//derived specs
// 
break_edge = (bolt_head_radius-bolt_radius)/3; //chamfer used to break sharp edges or help locate parts. I.e. bearing or bolt holes. Not the big bevel on the edges of most of the things.
chamfer = pulley_radius-bolt_radius-min_thick-break_edge-string_clearance; //Chamfer to break sharp corners and help with some tolerances, also looks cool. Beware, eats up your gear width (a little).   
{//bolt and bearing countersinks/bezels/seats
bolt_bezel = bolt_radius+wall_thick+chamfer;
bolt_head_bezel = bolt_head_radius+wall_thick+chamfer;
bolt_head_seat = bolt_head_thick+bearing_thick+washer;
bolt_sleeve = bolt_radius+break_edge+min_thick+chamfer;
bearing_bezel = bearing_radius+min_thick+chamfer+break_edge;
bearing_seat = bearing_thick+3*break_edge; 
effector_bearing_bezel = effector_bearing_radius+min_thick+chamfer+break_edge;
effector_bearing_seat = effector_bearing_thick+3*break_edge;
}

{//working out some details for the shoulder
shoulder_width = pulley_bolt-nut_thick+2*bolt_head_thick; 
shoulder_max = 0;
    //how high above the bed the shoulder reaches.
topside_shoulder = bolt_head_thick+washer+pulley_thick+washer+pulley_thick+washer;
frame_thick = base_bolt+bolt_head_thick-topside_shoulder-(bolt_head_seat)-washer-washer-(bolt_head_seat);//base_bolt-washer-pulley_thick-washer-pulley_thick-washer-(nut_thick+min_thick+2*break_edge)-washer-0-washer-min_thick-2*break_edge-nut_thick; 
}
fillet_radius = min(bearing_bezel+clearance-chamfer-pulley_radius-clearance, (shoulder_width/2-bolt_head_bezel-bolt_head_seat-chamfer-chamfer)/4); //making this too big results in odd artefacts
filleting_radius = fillet_radius+chamfer;

{//gear arm stuff 

{//details about the base
packing_circles =(2-sqrt(3))*(base_diameter-sqrt(3)*(bearing_radius+wall_thick/2));
drive_gear_cutouts = packing_circles-wall_thick/2-chamfer;
drive_gear_radius = drive_gear_cutouts-clearance-chamfer;
    
mm_per_tooth = drive_gear_radius*pi/(1+reel_teeth/2); 
motor_teeth = ceil((2*(motor_shaft_radius+wall_thick)*pi+4*mm_per_tooth)/mm_per_tooth); //teeth for the motor pinion
tooth_height = tooth_height(mm_per_tooth);
direct_drive = "false";//(pitch_radius(reel_teeth)+pitch_radius(motor_teeth)) < (bolt_radius+wall_thick+motor_width/2) ? "true":"false";
    
drive_gear_thick = ( direct_drive == "true" ? 0:(2*wall_thick) );
base_cut_angle = 10;
base_bolt_bezel = bolt_head_radius+wall_thick;
total_base_diameter = base_diameter+bearing_bezel+drive_gear_thick; //adds some extra material around the edges so the bolt holes end up as bolt holes not bites out of the corner.
center_distance = base_diameter/2/cos(30); //distance from corner to center of bed.
incircle_radius = base_diameter*(1-1/sqrt(3));    
    
base_cutout_circle = (total_base_diameter-(filleting_radius+drive_gear_thick))*tan(30-base_cut_angle)-(filleting_radius+drive_gear_thick);
base_cutout_distance = (total_base_diameter-(filleting_radius+drive_gear_thick))/cos(30-base_cut_angle);

}
{//details for the drive system    
driving_radius = pitch_radius(reel_teeth)+pitch_radius(motor_teeth);
drive_axle_offset = center_distance-bearing_radius-wall_thick/2-packing_circles;
cutout_xy = polar(base_cutout_distance, 60)+polar(center_distance, 240);
driven_reel_xy = [0, drive_axle_offset];
clearing_reel_xy = polar(drive_axle_offset, 120);
motor_xy = direct_drive == "true" ? polar((motor_width/2+chamfer+wall_thick/2)*tan(30)+motor_width/2+wall_thick/2, 60):int_circles(driven_reel_xy, driving_radius, clearing_reel_xy, driving_radius+tooth_height()+clearance)[1];
motor_mount_width = motor_width/2+chamfer+wall_thick+chamfer+drive_gear_thick;
motor_mount_rotation = direct_drive == "true" ? 60:90-atan((cutout_xy[1]-motor_xy[1])/(cutout_xy[0]-motor_xy[0]));




fillet_cutout_shift = (base_cutout_circle-sqrt(pow(base_cutout_circle,2)-pow(motor_mount_width,2)));
fillet_initial_shift = base_cutout_circle-fillet_cutout_shift-sqrt(pow(base_cutout_circle-(filleting_radius-chamfer), 2)-pow(motor_mount_width+(filleting_radius-chamfer), 2));
fillet_shift = base_cutout_circle-dist(cutout_xy, motor_xy)-fillet_cutout_shift;

fillet_for_thickness =  drive_gear_thick+filleting_radius-chamfer;
fillet_thickness = motor_mount_width; //sqrt(pow(fillet_for_thickness, 2)+pow(base_cutout_circle+chamfer-(base_cutout_circle+chamfer-sqrt(pow(base_cutout_circle+chamfer,2)-pow(motor_mount_width-chamfer,2)))-sqrt(pow(base_cutout_circle+chamfer-fillet_for_thickness, 2)-pow(motor_mount_width-chamfer+fillet_for_thickness, 2)), 2));

fillet_degrees = atan(fillet_initial_shift/(filleting_radius-chamfer))*2;

accessory_mount = min(2*(motor_mount_width-(filleting_radius+drive_gear_thick)-min_thick), pulley_bolt-nut_thick-4*(wall_thick+2*chamfer));

}
{//working out some details about how far the arm needs to reach
gear_width = pulley_bolt-2*(washer+pulley_thick+washer+pulley_thick+washer)-nut_thick;  
arm_elevation = shoulder_max-topside_shoulder+clearance+bearing_bezel;//(bearing_radius+min_thick+chamfer+break_edge)+clearance+(gear_width+2*(pulley_thick+2*washer))/2*tan(chamfer_angle);
    //-pulley_radius+(pulley_thick+2*washer)/2; //(-top_frame-pulley_radius-clearance); 
effector_middle = max(2*bolt_head_bezel, effector_bearing_seat+effector_bearing_thick);
effector_height = effector_middle/2+washer+effector_bearing_seat+washer+effector_bearing_seat+washer+wall_thick+hotend_height;
max_arm_lean_angle = atan((effector_height-arm_elevation)/(base_diameter+clearance));
min_effector_angle = atan((base_diameter/2)/(base_diameter*cos(30)-(base_diameter-2*print_radius-clearance)))*2;
    
effective_base_diameter = sqrt(pow(base_diameter+clearance, 2)+pow(effector_height-arm_elevation, 2)); //how far the arm will actually have to reach because of the space the effector takes up.
    
max_reach = ( (print_height > 0) && (print_radius > 0) ) ? sqrt(pow(base_diameter,2)+pow(print_height+effector_height-arm_elevation,2)):base_diameter;
}
{//minor details for the gear itself.
extra_space = 0; //any extra space you want between the shoulder pivot and gear for mounting or whatever. It mostly affects the gear radius. Adding space here reduces gear radius, which means less material usage but lower mechanical advantage.
pulley_offset = min_thick+chamfer+pulley_bore;
    //how far from the root radius of the gear the pulley is located. -offset moves it further out, +offset moves it closer in to the center of the gear.   
}
{//functions for working out details about the arms
//the nessecary pitch radius for any given maximum extension and spacing.
function joint_pitch_radius(angle, spacing=0, reach=max_reach)
    =(gear_teeth*(reach*secant(90-angle/2)-2*(bearing_bezel+extra_space+spacing)))/(2*(gear_teeth*secant(90-angle/2)+gear_teeth+1));
//checks if the pulleys collide with each other or each others' string.
function pulley_collision_check(angle, pitch_radius)
    = asin((2*pulley_radius+clearance+2*string_diameter)/(2*(pitch_radius-2*(pitch_radius/(2*gear_teeth))-pulley_offset))) < 90-angle/2 ? (2*pitch_radius-2*(pitch_radius-2*(pitch_radius/(2*gear_teeth))-pulley_offset)*cos(90-angle/2) > 2*(pulley_radius+clearance/2) ? "pass":"fail"):"fail";  
//the maximum extension angle for any given spacing, not accounting for collisions.
function angle(angle=180, spacing=0, reach=max_reach)
    =pulley_collision_check(angle, joint_pitch_radius(angle, spacing, reach))=="fail" ? angle(angle-angle_step, spacing, reach):angle;

//clearances for the gear above the surface of the bed.
function needed_clearance(spacing=0, angle=180)
    =joint_pitch_radius(angle, spacing)+(joint_pitch_radius(angle, spacing)/gear_teeth)-arm_elevation+clearance+shoulder_max;
function current_clearance(spacing=0, angle=180)
    =sin(max_arm_lean_angle+90-angle/2)*(joint_pitch_radius(angle, spacing)+(joint_pitch_radius(angle, spacing)/gear_teeth)+bearing_bezel+spacing+extra_space);  
function clearance_check(spacing, angle)
    =current_clearance(spacing, angle) > needed_clearance(spacing, angle) ? "pass":"fail";
    
//first checks the bed edge collision, second checks collision with the shoulder redirects.
function corner_collisions(pitch_radius, spacing, angle)
    =arm_offset(pitch_radius)-base_bolt_bezel-(bearing_bezel/cos(max_arm_lean_angle-angle/2))-clearance > -arm_elevation/tan(max_arm_lean_angle+(90-angle/2)) ? (arm_offset(pitch_radius)-bearing_bezel-(bearing_bezel/cos(max_arm_lean_angle-angle/2))-clearance > (shoulder_max-bolt_head_thick-arm_elevation)/tan(max_arm_lean_angle+(90-angle/2)) ? "pass":"fail"):"fail";

//the arm offset for any given pitch radius.
function arm_offset(pitch_radius)
    =max(sqrt(pow(total_base_diameter+clearance, 2)-pow(base_diameter*sin(30)-(shoulder_width/2), 2))-base_diameter*cos(30)+bolt_head_bezel, (clearance/2/sin((180-min_effector_angle)/2)+(gear_width/2+washer+bolt_head_seat))/tan(min_effector_angle/2)+bolt_head_bezel);

//checks collision between gear and top of build volume
    
function top_gear_center(pitch_radius, angle, spacing)
    =[(pitch_radius+pitch_radius/gear_teeth+spacing+bearing_bezel) * cos(-(atan(base_diameter/(print_height+effector_height-arm_elevation))-angle/2)), -(pitch_radius+pitch_radius/gear_teeth+spacing+bearing_bezel) * sin(-(atan(base_diameter/(print_height+effector_height-arm_elevation))-angle/2))];
    
function top_cylinder_top_gear_collision(pitch_radius, angle, spacing)
    =int_circle_line([top_gear_center(pitch_radius, angle, spacing)[0], top_gear_center(pitch_radius, angle, spacing)[1]+effector_height], pitch_radius+pitch_radius/gear_teeth+clearance, x_axis=1) == undef ? "pass":( int_circle_line([top_gear_center(pitch_radius, angle, spacing)[0], top_gear_center(pitch_radius, angle, spacing)[1]+effector_height], pitch_radius+pitch_radius/gear_teeth+clearance, x_axis=1)[1] > 2*print_radius-arm_offset(pitch_radius) ? "pass":"fail" );
    
function side_cylinder_top_gear_collision(pitch_radius, angle, spacing)
    =int_circle_line([top_gear_center(pitch_radius, angle, spacing)[0]+arm_offset(pitch_radius)-2*print_radius, top_gear_center(pitch_radius, angle, spacing)[1]], pitch_radius+pitch_radius/gear_teeth+clearance, y_axis=1) == undef ? "pass":( int_circle_line([top_gear_center(pitch_radius, angle, spacing)[0]+arm_offset(pitch_radius)-2*print_radius, top_gear_center(pitch_radius, angle, spacing)[1]], pitch_radius+pitch_radius/gear_teeth+clearance, y_axis=1)[1] > -effector_height ? "pass":"fail");

function side_gear_center(pitch_radius, angle, spacing)
    =[(bearing_bezel+spacing+pitch_radius+pitch_radius/gear_teeth) * sin(-(atan((print_height+effector_height-arm_elevation)/base_diameter)-angle/2)), (bearing_bezel+spacing+pitch_radius+pitch_radius/gear_teeth) * cos(-(atan((print_height+effector_height-arm_elevation)/base_diameter)-angle/2))];
    
function top_cylinder_side_gear_collision(pitch_radius, angle, spacing)
    =int_circle_line([(base_diameter-2*print_radius)+arm_offset(pitch_radius)-side_gear_center(pitch_radius, angle, spacing)[0], side_gear_center(pitch_radius, angle, spacing)[1]+arm_elevation-print_height], pitch_radius+pitch_radius/gear_teeth+clearance, x_axis=1) == undef ? "pass":( int_circle_line([(base_diameter-2*print_radius)+arm_offset(pitch_radius)-side_gear_center(pitch_radius, angle, spacing)[0], side_gear_center(pitch_radius, angle, spacing)[1]+arm_elevation-print_height], pitch_radius+pitch_radius/gear_teeth+clearance, x_axis=1)[1] > 0 ? "pass":"fail");
    
function side_cylinder_side_gear_collision(pitch_radius, angle, spacing)
    =int_circle_line([(base_diameter-2*print_radius)+arm_offset(pitch_radius)-side_gear_center(pitch_radius, angle, spacing)[0], side_gear_center(pitch_radius, angle, spacing)[1]+arm_elevation], pitch_radius+pitch_radius/gear_teeth+clearance, y_axis=1) == undef ? "pass":( int_circle_line([(base_diameter-2*print_radius)+arm_offset(pitch_radius)-side_gear_center(pitch_radius, angle, spacing)[0], side_gear_center(pitch_radius, angle, spacing)[1]+arm_elevation], pitch_radius+pitch_radius/gear_teeth+clearance, y_axis=1)[1] > print_height ? "pass":"fail");
    


function cylinder_collision_checks(pitch_radius, angle, spacing)
    =(top_cylinder_top_gear_collision(pitch_radius, angle, spacing) == "pass") && (side_cylinder_top_gear_collision(pitch_radius, angle, spacing) == "pass") && (side_cylinder_side_gear_collision(pitch_radius, angle, spacing) == "pass") && (side_cylinder_side_gear_collision(pitch_radius, angle, spacing) == "pass") ? "pass":"fail";
   

//uses all of the above to work out the extension angle and spacing needed for the arms.

function all_checks(spacing=0, angle=180, reach=max_reach)
    =( (clearance_check(spacing, angle) == "pass") && (corner_collisions(joint_pitch_radius(angle, spacing, reach), spacing, angle) == "pass") && (cylinder_collision_checks(joint_pitch_radius(angle, spacing, reach), angle, spacing) == "pass") ) ? "pass":"fail";
    
function arm_details(spacing = 0, angle = 180, reach = max_reach)
    =angle < 0 ? arm_details(0, angle(180, 0, reach+reach_step), reach+reach_step):(all_checks(spacing, angle, reach) == "pass" ? [angle, spacing, reach]:arm_details((spacing+spacing_step), angle(angle, spacing, reach)-angle_step, reach));
    
    //all_checks(spacing, angle) == "pass" ? [angle, spacing]:arm_details(spacing+spacing_step, angle(angle, spacing)-angle_step);
    
    //clearance_check(spacing, angle) == "fail" ? arm_details(spacing+spacing_step, angle(angle, spacing)):(corner_collisions(joint_pitch_radius(angle, spacing), spacing, angle) == "fail" ? arm_details(0, angle(angle, spacing)-angle_step):[angle, spacing]);
    
    
//Iterative solving, because I couldn't for the life of me directly solve for the maximum possible extension angle and the nessecary spacing. Wolfram|alpha gave me errors when I tried.
}

{//finalizing the dimensions for the arm
max_extension = arm_details();
extension_angle = max_extension[0];
minimum_spacing = max_extension[1];
total_reach = max_extension[2];
//the maximum angle the arm can extend, and the spacing required between the shoulder pivot and the gear on the arm.
gear_spokes = floor(number_gear_spokes/2)*2; 
//told you I was checking...

//details for the gear joint.
pitch_radius = joint_pitch_radius(extension_angle, minimum_spacing);
tooth_radius = pitch_radius/(2*gear_teeth);  
//the horizontal offset of the arm from the base of the printer.
arm_offset = arm_offset(pitch_radius); 

arm_length = 2*(pitch_radius+2*tooth_radius)+2*bearing_bezel+chamfer+extra_space+minimum_spacing;//length of one link of the arm.
    //needs space for the gear and pivot. 
effective_arm_length = arm_length-bearing_bezel;
home_angle = acos(center_distance/total_reach);
}
}

{//shoulder stuff
//checking the arm offset is ok, especially if you've changed it
shoulder_diagonal=sqrt(pow(arm_offset-bearing_bezel, 2)+pow(shoulder_width/2, 2));
int_pts=int_circles([-base_diameter,0], total_base_diameter, [0,0], shoulder_diagonal)[1];    
max_shoulder_angle=120-(atan(int_pts[0]/int_pts[1])+atan((shoulder_width/2)/(arm_offset-bearing_bezel)));
}
}
{//echo machine details
//echo("base diameter", total_base_diameter+bearing_bezel+drive_gear_thick);
//echo("print bed needed", max(arm_length, total_base_diameter+bearing_bezel+drive_gear_thick));
//echo("suggested_base_diameter", suggested_base_diameter);
//to do with print volumes and stuff    
//echo("incircle diameter of bed", 2*base_diameter*(1-1/sqrt(3)));
//echo("max height", sqrt(pow(base_diameter, 2)-pow(base_diameter/2, 2))); 
//echo("print volume", pow(base_diameter, 3)/(6*sqrt(2))); //this is the size of the pyramid that fits in the build volume, you should get a bit more because of the bulging sides.
    
    
//to do with sizes of parts and stuff    
//echo("max arm extension angle", extension_angle);
//echo("gear pitch radius",pitch_radius);
//echo("gear tooth radius", tooth_radius);
//echo("arm length", arm_length);
//echo("arm offset", arm_offset);
//echo("arm width", gear_width);
//echo("shoulder width", shoulder_width);
//echo("frame_space", shoulder_height);
//echo("max shoulder angle", max_shoulder_angle); //must be 60 or over to access full build volume. If you've left it at default and have clearance set to more than zero it should be over 60.
    
    
    flat_angle = 2*asin(((effective_base_diameter-2*pitch_radius)/2)/(pitch_radius+tooth_radius*2+minimum_spacing+bearing_bezel));
//echo("flat angle", flat_angle);

}
{//debug. Uncomment this to see why it's not rendering or looks funny and to make sure your hardware will produce a functioning machine


}
{//rough accuracy calc UNFINISHED
step_angle = 1.8;
microstepping  = 16;
spool_radius = direct_drive == "true" ? (motor_shaft_radius+wall_thick):(root_radius(reel_teeth)-chamfer-break_edge);
string_per_step = (2*pi*spool_radius)/360*step_angle/microstepping;
arm_lever = (arm_length-pitch_radius-2*tooth_radius-bearing_bezel-chamfer)/(pitch_radius-2*tooth_radius-pulley_offset);
delta_radius_per_step = string_per_step/4*arm_lever;

echo("steps per mm", 1/delta_radius_per_step);
}

}

{//gear arm
module chamfered_gear(start, teeth, shift)
{
    difference()
    {
        rotate([0, 0, -180/gear_teeth*shift])
        union()
        {
            for ( i = [ 0 : 1 ] )
            {
                translate([0,0,chamfer*tan(chamfer_angle)+i*((gear_width-2*chamfer*tan(chamfer_angle))/2+break_edge/2)])
                rotate([0,0,-i*gear_twist*360/gear_teeth])
                c_gear(gear_teeth, (gear_width-2*chamfer*tan(chamfer_angle))/2-break_edge/2, start=start, shown_teeth=teeth, helix=1, twist=gear_twist*pow(-1, i), chamfer=0, res=res);
            }
        
        
            translate([0,0,chamfer*tan(chamfer_angle)+((gear_width-2*chamfer*tan(chamfer_angle))/2-break_edge/2)])
            rotate([0,0,-360/gear_teeth*gear_twist])
            c_gear(gear_teeth,  break_edge, start=start, shown_teeth=teeth, helix=1, twist=0, chamfer=0, res=res);
            
            for ( i = [ 0 : 1 ] )
            translate([0,0,chamfer*tan(chamfer_angle)+i*(gear_width-2*chamfer*tan(chamfer_angle))])
            mirror([0,0,1-i])
            c_gear(gear_teeth, chamfer*tan(chamfer_angle), tooth_radius, start=start, shown_teeth=teeth, helix=1, twist=0, res=res, scaling=(pitch_radius+2*tooth_radius-chamfer)/(pitch_radius+2*tooth_radius));
        }
        
        translate(-[pitch_radius+2*tooth_radius, (pitch_radius+2*tooth_radius), 0])
        cube([pitch_radius+2*tooth_radius, 2*(pitch_radius+2*tooth_radius), gear_width]);
    }
}
 
        
        
module elbow_gear(shift, round_over, scaling, chamfer_altered, chamfer_angle_altered)//hull the last few teeth before the limb, looks nicer? can add an easy fillet then.
{
    
    scaling = (pitch_radius+2*tooth_radius-chamfer)/(pitch_radius+2*tooth_radius);
    
    
    approx_arc_segment = (res/(2*pi*pitch_radius)*360);
    arc_segment=(90/gear_teeth)/ceil((90/gear_teeth)/approx_arc_segment);
    segments_per_tooth = (360/(gear_teeth*2)/arc_segment);
    
    teeth_to_show = gear_teeth;//gear_teeth%2 == 1 ? (gear_twist < 0.5 ? gear_teeth-2.5 : gear_teeth-0.5-2*floor(gear_twist/0.5)) : gear_teeth-1.5-2*floor(gear_twist);
        
        chamfered_gear(0.25-shift/2, teeth_to_show, shift, gear_twist);
        hull()
        {
            for ( i = [ -1 : 1 ] )
                translate([0, i*(pitch_radius+pow(-1, shift)*2*tooth_radius-round_over), 0]) ///roundover migt need to be chamfer+min_thick
                
            cylinder_c(gear_width, round_over);
                //cylinder_c(gear_width, round_over, chamfer=i==0 ? chamfer:(shift<1 ? chamfer:chamfer_altered), angle=i<1 ? chamfer_angle:(shift==0 ? chamfer_angle:chamfer_angle_altered));
        }
        
        for ( i = [ 0 : 1 ] )
        translate([0, 0, i*(gear_width)])
        mirror([0, 0, i])
        hull()
        {
            translate([0, pitch_radius+pow(-1, shift)*2*tooth_radius-round_over])
            cylinder_c(gear_width/2, round_over, chamfer=0, chamfer1=chamfer, angle1=chamfer_angle);
            chamfered_gear(0.25-shift/2, 1/segments_per_tooth, shift, gear_twist);
        }
        
        rotate([0, 0, -90])
            cylinder_c(gear_width, pitch_radius-2*tooth_radius-chamfer, chamfer=chamfer, deg=180);
    
    //twist for chamfer     chamfer*tan(chamfer_angle)/(gear_width/2-chamfer*tan(chamfer_angle)-break_edge)*gear_twist
        //chamfered_gear(gear_teeth%2==0 ? gear_teeth/2-0.75-2*gear_twist : gear_teeth/2-0.25-2*gear_twist, 0.5, shift);

}
module gear_cutouts(shift)
{
    //here "hub" is the gear hub, where all the spokes meet up
    cutouts = gear_spokes+1;
    bolt_sleeve_arc = atan((bolt_radius+chamfer)/(pitch_radius-2*tooth_radius-pulley_offset)); //how many degrees are taken up by the bolt sleeve
    cutout_arc = (180-2*bolt_sleeve_arc)/cutouts; //how many degrees the cutouts are apart.
    cutout_radii = filleting_radius;
    cutout_poly_sides = cutout_radii+wall_thick;
    hub_radius = (2*cutout_poly_sides)/(2*sin(180/(cutouts*2)));
    hub_inradius = hub_radius*cos(180/(cutouts*2));
    cutout_max_radius = pitch_radius-2*tooth_radius-wall_thick*2-cutout_radii;
    
    
    rotate([0, 0, cutout_arc/2-bolt_sleeve_arc+0*180])
    for ( j = [ 1 : cutouts ] )
            rotate([0, 0, -j*cutout_arc])
            translate([0, hub_inradius, 0])
    
    {
                
                translate([0, 0, -chamfer])
                poly_cylinder_c(
                [ 
                [polar(cutout_max_radius-hub_inradius, -cutout_arc/2)[0], polar(cutout_max_radius-hub_inradius, -cutout_arc/2)[1]+(cutout_max_radius-hub_inradius)*0, 0],
                [polar(cutout_max_radius-hub_inradius, cutout_arc/2)[0], polar(cutout_max_radius-hub_inradius, cutout_arc/2)[1]+(cutout_max_radius-hub_inradius)*0, 0],
                [0, 0, 0]
                ], 
    gear_width+2*chamfer, cutout_radii-chamfer, 2*chamfer);
                
    }
    
    
    *for ( i = [ 0 : 2 ] )
    translate([0, 0, -chamfer*tan(chamfer_angle)+(i == 2 ? gear_width:0)])
    rotate([0, 0, cutout_arc/2-bolt_sleeve_arc])
    for ( j = [ 1 : cutouts ] )
            rotate([0, 0, -j*cutout_arc])
            translate([0, hub_inradius, 0])
            hull()
            {
                
                //redo this with poly_cylinder_c
                
                cylinder_c(i > 0 ? 2*chamfer*tan(chamfer_angle) : gear_width+2*chamfer*tan(chamfer_angle), cutout_radii, chamfer=0, chamfer1=i == 1 ? -2*chamfer : 0, chamfer2=i == 2 ? -2*chamfer : 0, angle1=chamfer_angle, angle2=chamfer_angle);
                for ( k = [ -1 : 2 : 1 ] )
                    //rotate([0, 0, k*cutout_arc/2])
                    translate(polar(cutout_max_radius-hub_inradius, k*cutout_arc/2))
                    rotate([0, 0, -90])
                    //translate([0, cutout_max_radius-hub_inradius, 0])
                    cylinder_c(i > 0 ? 2*chamfer : gear_width+2*chamfer, cutout_radii, chamfer=0, chamfer1=i == 1 ? -2*chamfer : 0, chamfer2=i == 2 ? -2*chamfer : 0, angle1=chamfer_angle, angle2=chamfer_angle);
                
            }
    
    if ( shift == 0 )
    {
                //nut trap for the bolt that holds the pulley which redirects string from one side oft he arm to the other
        translate([hub_inradius-cutout_radii, 0, gear_width/2])
        rotate([0, 90, 0])
        cylinder_c((cutout_max_radius-hub_inradius)*cos(cutout_arc/2), (nut_radius+tolerance)/cos(30), chamfer=break_edge, res=2*pi*(nut_radius+tolerance)/cos(30)/6); 

                //hole for the bolt itself
        translate([hub_inradius-cutout_radii+break_edge, 0, gear_width/2])
        rotate([0, -90, 0]) 
        cylinder_c(fillet_radius+chamfer+hub_inradius-cutout_radii+2*break_edge, bolt_radius+tolerance, chamfer1=-2*break_edge, chamfer2=-2*break_edge);
                
                
        //HACK TO LET ME USE ONLY ONE LENGTH OF BOLT. DO NOT USE THIS JUST GET A SHORTER BOLT.
        bore_depth = pulley_bolt-2*washer-pulley_thick-1*wall_thick-(hub_inradius+(cutout_max_radius-hub_inradius)*cos(cutout_arc/2)+cutout_radii)-chamfer-fillet_radius;
        //-wall_thick to accomodate a bolt cap enclosed in a drag chain link for the limit switch. Unless I'm using trinamic drivers, then no limit switches and it would just barely work with no wall spacing and the gear teeth size I've got.
                
        translate([hub_inradius+(cutout_max_radius-hub_inradius)*cos(cutout_arc/2)+cutout_radii-break_edge, 0, gear_width/2])
        rotate([0, 90, 0])
        cylinder_c(bore_depth+break_edge, bolt_radius+tolerance, chamfer1=-2*break_edge, chamfer2=break_edge); 
        //DO NOT USE THE ABOVE.      
    }
            
            
}
module bolt_sleeve_fillet(round_over)
{

    hyp = filleting_radius+bolt_sleeve;
    opp = round_over+filleting_radius;
    adj = sqrt(pow(hyp,2)-pow(opp,2));
    difference()
    {
        linear_extrude(gear_width)
        polygon([ [0,0], [0, adj], [-opp, adj] ]);
        translate([-opp, adj, -chamfer])
        cylinder_c(gear_width+2*chamfer, filleting_radius, chamfer=-2*chamfer, angle=chamfer_angle);
    }
}
module spine_rounding(round_over)
{
    //have adj and part of hyp, need to solve for fillet radius
    
    adj = pitch_radius-2*tooth_radius-pulley_offset-pulley_radius-string_clearance;
    spine_filleting_radius = (pow(adj,2)-pow(bolt_sleeve,2)+pow(round_over,2))/(2*bolt_sleeve-2*round_over);
    hyp = spine_filleting_radius+bolt_sleeve;
    opp = round_over+spine_filleting_radius;
    
    
    if ( spine_filleting_radius > 0 )
    difference()
    {
        linear_extrude(gear_width)
        polygon([ [0,0], [0, adj], [-opp, adj] ]);
        translate([-opp, adj, -chamfer])
        cylinder_c(gear_width+2*chamfer, spine_filleting_radius, chamfer=-2*chamfer);
    }

}
module arm(shift) //0 shift for driving arm, 1 shift for driven arm
{     
    scaling = (pitch_radius+2*tooth_radius-chamfer)/(pitch_radius+2*tooth_radius);

    chamfer_altered = (pitch_radius-2*tooth_radius)*(1-scaling);
    chamfer_angle_altered = atan((chamfer*tan(chamfer_angle))/chamfer_altered);
    
    round_over = filleting_radius;

            difference()
            {
                union()
                {
                    elbow_gear(shift, round_over, scaling, chamfer_altered, chamfer_angle_altered);
                    *hull() //first slant along spine
                    {
                        cylinder_c(gear_width, round_over, angle=chamfer_angle);
                        
                        
                        translate([0, -(pitch_radius-2*tooth_radius-pulley_offset), 0])
                        cylinder_c(gear_width, bolt_radius+min_thick+chamfer, angle=chamfer_angle);         
                    }  
                   
                    hull() //second slant
                    {
                        translate([0, -(pitch_radius-2*tooth_radius-pulley_offset), 0])
                        cylinder_c(gear_width, bolt_sleeve, angle=chamfer_angle);  
                        
                        translate([0, -(pitch_radius-2*tooth_radius-pulley_offset), 0])
                        rotate([0, 0, -90])
                        cylinder_c(gear_width, (bearing_bezel+bolt_bezel)/2, angle=chamfer_angle, deg=180);  
                        
                        translate([0, -(arm_length-pitch_radius-2*tooth_radius-bearing_bezel-chamfer), 0])
                        cylinder_c(gear_width, bearing_bezel, angle=chamfer_angle);           
                    }   
                
                    for ( i = [ -1 : 2 : 1 ] )
                        hull() //bolt sleeves
                        {
                            translate([0, i*(pitch_radius-2*tooth_radius-pulley_offset), 0])
                            cylinder_c(gear_width, bolt_sleeve);
                            *if ( ( i == 1 ) && ( shift == 1) )
                                translate([0, pitch_radius-2*tooth_radius-round_over, 0])
                                cylinder_c(gear_width, round_over, chamfer=chamfer_altered, angle=chamfer_angle_altered);
                        }
                    translate([0, pitch_radius-2*tooth_radius-pulley_offset, 0])
                    for ( i = [ 1 : 2-shift ] )
                        mirror([0, i%2, 0])
                        bolt_sleeve_fillet(round_over);
                    
                    translate([0, -pitch_radius+2*tooth_radius+pulley_offset, 0])
                    
                    spine_rounding(round_over);
                }
                
                translate([0, -(arm_length-pitch_radius-2*tooth_radius-bearing_bezel-chamfer), 0])
                translate([0, 0, -break_edge])
                cylinder_c(gear_width+2*break_edge, bearing_radius+tolerance, chamfer=-2*break_edge);
                
                gear_cutouts(shift);
                
                for ( i = [ -1 : 2 : 1 ] )
                    translate([0, i*(pitch_radius-2*tooth_radius-pulley_offset), -break_edge])
                    cylinder_c(gear_width+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);
                
                *if ( shift == 0 )
                {
                    translate([-fillet_radius-chamfer, 0, gear_width/2])
                    rotate([0, -90, 0])
                    cylinder_c(pulley_thick+chamfer, pulley_radius+clearance+chamfer, angle=chamfer_angle);
                }
                

            }
    translate([0, -pitch_radius-2*tooth_radius-extra_space-minimum_spacing-bearing_bezel, bearing_thick])
    cylinder_c_internal(gear_width-2*bearing_thick, bolt_radius+tolerance, chamfer=bearing_radius-bolt_radius, angle=chamfer_angle, thick=min_thick+break_edge);
}

module arm_model(rot_a=-extension_angle)
{
arm(0);    
rotate([0,0,-rot_a/2])
translate([2*pitch_radius, 0, 0])
rotate([0,0,-rot_a/2])
mirror([1,0,0])  
arm(1);
}
module elbow_joint_model(rot_a=-extension_angle)
{
arm(0);    
rotate([0,0,-rot_a/2])
translate([2*pitch_radius, 0, 0])
rotate([0,0,-rot_a/2])
mirror([1,0,0])  
arm(1);
//visual check if the pulleys colide with the strings of the other pulleys
hull()
{
    rotate([0,0,-rot_a/2])
    translate([2*cycloid_joint_pitch_radius(gear_teeth), 0, 0])
    rotate([0,0,-rot_a/2])
    mirror([1,0,0])
    translate([0, (pitch_radius-2*tooth_radius-pulley_offset), gear_width])
cylinder(pulley_thick, r=pulley_radius+string_diameter+clearance);
    
    translate([0, (pitch_radius-2*tooth_radius-pulley_offset), gear_width])
cylinder(pulley_thick, r=pulley_radius+string_diameter+clearance);
}
color(color_metal)
{//visually check if the pulleys physically colide.
rotate([0,0,-rot_a/2])
    translate([2*cycloid_joint_pitch_radius(gear_teeth), 0, 0])
    rotate([0,0,-rot_a/2])
    mirror([1,0,0])
    translate([0, (pitch_radius-2*tooth_radius-pulley_offset), gear_width])
cylinder(2*pulley_thick, r=pulley_radius+string_diameter+clearance/2);
    
    translate([0, (pitch_radius-2*tooth_radius-pulley_offset), gear_width])
cylinder(2*pulley_thick, r=pulley_radius+string_diameter+clearance/2);
}
hull()
{
    rotate([0,0,-rot_a/2])
    translate([2*cycloid_joint_pitch_radius(gear_teeth), 0, 0])
    rotate([0,0,-rot_a/2])
    mirror([1,0,0])
    translate([0, -(pitch_radius-2*tooth_radius-pulley_offset), gear_width])
cylinder(pulley_thick, r=pulley_radius+string_diameter);
    
    translate([0, -(pitch_radius-2*tooth_radius-pulley_offset), gear_width])
cylinder(pulley_thick, r=pulley_radius+string_diameter);
}
}


*translate([-fillet_radius-chamfer-pulley_thick-2*washer-2*wall_thick, 0, gear_width/2])
rotate([0, 90, 0])
cylinder(pulley_bolt, r=2);
*difference()//CROSS SECTION
{
arm(0);
translate([-pitch_radius/2,-pitch_radius-2*tooth_radius-2*bearing_bezel-chamfer,gear_width/2])
cube([2*pitch_radius, arm_length, gear_width]);
}
//elbow_joint_model();
*for(j=[0:1])
mirror([0, 0, j])
for(i=[-1:2:1])
translate([0, i*(pitch_radius-2*tooth_radius-pulley_offset), (j-1)*-2*gear_width/2])
color(color_metal)
{
cylinder(3*washer+2*pulley_thick, r=pulley_radius);
cylinder(2*washer+2*pulley_thick+bolt_head_thick, r=bolt_head_radius);
}

//arm model
*translate([0, arm_offset, arm_elevation])

rotate([-atan((print_height+effector_height-arm_elevation)/base_diameter), 0, 0])
//rotate([-max_arm_lean_angle, 0, 0])

//rotate([180-(90-flat_angle/2), 0, 0])
rotate([180-(90-extension_angle/2), 0, 0])

rotate([0, -90, 0])
translate([0, pitch_radius+bearing_bezel+2*tooth_radius+extra_space+minimum_spacing, -gear_width/2])
{
    elbow_joint_model();
}
}
{//shoulder
module shoulder_arm_yoke(filleting_radius)
{   
    hull() //side plates for the yoke
    {
        //bezel for bolt
        translate([shoulder_width/2, arm_offset, arm_elevation])
        rotate([0, -90, 0])
        cylinder_c(bolt_head_seat, bolt_head_bezel, res=circle_res_correction(bolt_head_seat));
        
        translate([shoulder_width/2-bolt_head_seat+chamfer, arm_offset-bolt_head_bezel, arm_elevation-chamfer])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer));
        
        translate([shoulder_width/2-chamfer, arm_offset-bolt_head_bezel, arm_elevation-chamfer])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer));
    }
    
    difference() // the rest of the yoke
    {
    hull() //blank for the yoke
    {
        translate([0, arm_offset-bolt_head_bezel, arm_elevation-chamfer])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer));
        
        translate([shoulder_width/2-chamfer, arm_offset-bolt_head_bezel, arm_elevation-chamfer])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer));

        translate([shoulder_width/2-filleting_radius, arm_offset-bolt_head_bezel, arm_elevation-bearing_bezel-clearance-bolt_head_seat+filleting_radius+2*chamfer])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, filleting_radius, res=circle_res_correction(filleting_radius));
        
        translate([shoulder_width/2-filleting_radius-2*chamfer*tan(chamfer_angle), arm_offset-bolt_head_bezel, arm_elevation-bearing_bezel-clearance-bolt_head_seat+filleting_radius])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, filleting_radius, res=circle_res_correction(filleting_radius));
        
        translate([0, arm_offset-bolt_head_bezel, arm_elevation-bearing_bezel-clearance-bolt_head_seat+filleting_radius])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, filleting_radius, res=circle_res_correction(filleting_radius));
    }
    
    
        //cutouts for the yoke
    translate([0, arm_offset-bolt_head_bezel-chamfer, arm_elevation])
    rotate([-90,0,0])
    poly_cylinder_c(
    [ 
    [-filleting_radius, -filleting_radius, 0], 
    [gear_width/2+washer+pulley_thick+washer-filleting_radius+chamfer, -filleting_radius, 0], 
    [gear_width/2+washer+pulley_thick+washer-filleting_radius+chamfer, bearing_bezel-filleting_radius+chamfer+clearance-chamfer,0], 
    [gear_width/2+washer+pulley_thick+washer-filleting_radius+chamfer-chamfer*tan(chamfer_angle), bearing_bezel-filleting_radius+chamfer+clearance,0],
    [-filleting_radius, bearing_bezel-filleting_radius+chamfer+clearance,0] 
    ], 
    bolt_head_bezel*2+2*chamfer, filleting_radius-chamfer, 2*chamfer, res=circle_res_correction(filleting_radius+chamfer));
    }
}
module shoulder_body(filleting_radius)
{
    shoulder_taper = shoulder_width/2-bolt_head_bezel-2*chamfer-filleting_radius-filleting_radius+chamfer-chamfer;
    
    
    difference() //taper
    {
    
    hull() //taper blank
    {
        translate([0, arm_offset-bolt_head_bezel, shoulder_max-topside_shoulder-bolt_head_seat+chamfer])
        rotate([-90,0,0])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer));
        
        translate([bolt_head_bezel+filleting_radius-chamfer+shoulder_taper, arm_offset-bolt_head_bezel, shoulder_max-topside_shoulder-bolt_head_seat+chamfer])
        rotate([-90,0,0])
        rotate([0, 0, -180])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer), deg=90);
        
        
        translate([0, arm_offset-bolt_head_bezel, shoulder_max-topside_shoulder-bolt_head_seat-(filleting_radius-chamfer+shoulder_taper*tan(chamfer_angle))])
        rotate([-90,0,0])
        rotate([0, 0, 180])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer), deg=180);
        
        translate([bolt_head_bezel+filleting_radius-chamfer+shoulder_taper, arm_offset-bolt_head_bezel, shoulder_max-topside_shoulder-bolt_head_seat-(filleting_radius-chamfer+shoulder_taper*tan(chamfer_angle))])
        rotate([-90,0,0])
        rotate([0, 0, -180])
        cylinder_c(bolt_head_bezel*2, chamfer, res=circle_res_correction(chamfer), deg=90);
    }
    
    
        //taper cutout
    translate([0, arm_offset-bolt_head_bezel-chamfer, shoulder_max-topside_shoulder-bolt_head_seat])
    rotate([-90, 0, 0])
    poly_cylinder_c(
    [
    [bolt_head_bezel+filleting_radius-chamfer+shoulder_taper, filleting_radius-chamfer, 0],
    [bolt_head_bezel+filleting_radius-chamfer+shoulder_taper+chamfer, filleting_radius-chamfer, 0],
    [bolt_head_bezel+filleting_radius-chamfer, filleting_radius-chamfer+shoulder_taper*tan(chamfer_angle), 0],
    [bolt_head_bezel+filleting_radius-chamfer, filleting_radius-chamfer+shoulder_taper*tan(chamfer_angle)+chamfer, 0],
    [bolt_head_bezel+filleting_radius-chamfer+shoulder_taper+chamfer, filleting_radius-chamfer+shoulder_taper*tan(chamfer_angle)+chamfer, 0]
    ],
    bolt_head_bezel*2+2*chamfer, filleting_radius-chamfer, 2*chamfer, res=circle_res_correction(filleting_radius+chamfer));    
    }
  
    //
    rear_chamfer = min((base_bolt+bolt_head_thick-topside_shoulder-bolt_head_seat-shoulder_taper-filleting_radius+chamfer), (2*bolt_head_bezel-2*filleting_radius)*tan(chamfer_angle));//bolt_head_bezel-2*filleting_radius, 
    hull() //shoulder body 
    {
    translate([bolt_head_bezel, arm_offset+bolt_head_bezel-filleting_radius, shoulder_max-topside_shoulder-bolt_head_seat+chamfer-shoulder_taper-filleting_radius])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));
    
    translate([bolt_head_bezel, arm_offset+bolt_head_bezel-filleting_radius, shoulder_max-base_bolt-bolt_head_thick+filleting_radius+rear_chamfer])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));
    
    translate([bolt_head_bezel, arm_offset+bolt_head_bezel-filleting_radius-rear_chamfer*tan(chamfer_angle), shoulder_max-base_bolt-bolt_head_thick+filleting_radius])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));
    
    translate([bolt_head_bezel, arm_offset-bolt_head_bezel+filleting_radius, shoulder_max-base_bolt-bolt_head_thick+filleting_radius])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));
        
    translate([bolt_head_bezel, arm_offset-bolt_head_bezel+filleting_radius, shoulder_max-topside_shoulder-bolt_head_seat+chamfer-shoulder_taper-filleting_radius])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));    
    }
    
    
    shoulder_corner_brace = sqrt(pow(total_base_diameter+clearance, 2)-pow(base_diameter*sin(30)-(bolt_head_bezel), 2))-base_diameter*cos(30)+chamfer;
    
    //a chamfer for the sides the top half of the yoke.
    for ( i = [ -1 : 2 : 1 ] )
    {    
    translate([i*bolt_head_bezel, arm_offset-bolt_head_bezel, shoulder_max-topside_shoulder-bolt_head_seat/2])
    {
    rotate([0, i*90, 0])
    inside_filleted_chamfer(bolt_head_seat, chamfer, filleting_radius);    
    
    mirror([i-1,0,0])
    translate([-chamfer, 0, -bolt_head_seat/2+chamfer])
    corner_chamfer_transition(chamfer, filleting_radius);
    }    
    }
    
    //a chamfer for the bottom of the top half of the yoke
    translate([0, arm_offset-bolt_head_bezel, shoulder_max-topside_shoulder-bolt_head_seat])
    mirror([0,0,1])
    inside_filleted_chamfer(2*bolt_head_bezel, chamfer, filleting_radius);
    
    //a chamfer for the bottom part of the yoke
    translate([0, arm_offset-bolt_head_bezel, shoulder_max-base_bolt-bolt_head_thick+bolt_head_seat])
    inside_filleted_chamfer(2*bolt_head_bezel, min(arm_offset-shoulder_corner_brace-bolt_head_bezel, base_bolt+bolt_head_thick-topside_shoulder-bolt_head_seat*2-shoulder_taper-2*(filleting_radius-chamfer)), filleting_radius);

}
module inside_filleted_chamfer(width, chamfer_size, filleting_radius)
{
    //a filleted chamfer for an inside corner.
    rotate([0, 90, 0])
    difference()    //corner chamfer
    {
    hull()  //corner chamfer blank
    {
        translate([chamfer, chamfer, -width/2])
        cylinder_c(width, chamfer, res=circle_res_correction(chamfer)); 
        
        translate([-(filleting_radius-chamfer)-chamfer_size, chamfer, -width/2])
        cylinder_c(width, chamfer, res=circle_res_correction(chamfer), deg=90); 
       
        translate([-(filleting_radius-chamfer)-chamfer_size, -(filleting_radius-chamfer)-chamfer_size, -width/2])
        cylinder_c(width, chamfer, res=circle_res_correction(chamfer), deg=90);  
        
        translate([chamfer, -(filleting_radius-chamfer)-chamfer_size, -width/2])
        cylinder_c(width, chamfer, res=circle_res_correction(chamfer), deg=90); 
    }    

    
        //corner chamfer cutouts
    translate([0, 0, -width/2-chamfer])
    poly_cylinder_c(
    [ 
    [-filleting_radius+chamfer, -filleting_radius+chamfer-chamfer_size, 0],
    [-filleting_radius+chamfer, -filleting_radius-chamfer-chamfer_size, 0],
    [-filleting_radius-chamfer-chamfer_size, -filleting_radius-chamfer-chamfer_size, 0],
    [-filleting_radius-chamfer-chamfer_size, -filleting_radius+chamfer, 0],
    [-filleting_radius+chamfer-chamfer_size*tan(chamfer_angle), -filleting_radius+chamfer, 0]
    ], 
    width+2*chamfer, filleting_radius-chamfer, 2*chamfer, res=circle_res_correction(filleting_radius+chamfer));
    }
}

module corner_chamfer_transition(chamfer, filleting_radius)
{
    
    difference()
    {
        translate([0, -(filleting_radius+chamfer), -(filleting_radius+chamfer)])
        cube([filleting_radius+chamfer, filleting_radius+chamfer, filleting_radius+chamfer]);
    
    hull()
        {
    translate([chamfer, -chamfer, -chamfer])
    mirror([1,0,0])
    pit_c(
    [ 
    [-filleting_radius+chamfer, -filleting_radius+chamfer-chamfer, 0],
    [-filleting_radius+chamfer, -filleting_radius-chamfer-chamfer, 0],
    [-filleting_radius-chamfer-chamfer, -filleting_radius-chamfer-chamfer, 0],
    [-filleting_radius-chamfer-chamfer, -filleting_radius+chamfer, 0],
    [-filleting_radius+chamfer-chamfer*tan(chamfer_angle), -filleting_radius+chamfer, 0]
    ], 
    filleting_radius-chamfer, chamfer, resolution=circle_res_correction(filleting_radius));
    
    translate([chamfer*tan(chamfer_angle), -chamfer, -chamfer])
    rotate([0, -90, 0])
    pit_c(
    [ 
    [-filleting_radius+chamfer, -filleting_radius+chamfer-chamfer, 0],
    [-filleting_radius+chamfer, -filleting_radius-chamfer-chamfer, 0],
    [-filleting_radius-chamfer-chamfer, -filleting_radius-chamfer-chamfer, 0],
    [-filleting_radius-chamfer-chamfer, -filleting_radius+chamfer, 0],
    [-filleting_radius+chamfer-chamfer*tan(chamfer_angle), -filleting_radius+chamfer, 0]
    ], 
    filleting_radius-chamfer, chamfer, resolution=circle_res_correction(filleting_radius));
    
    translate([(2*filleting_radius-chamfer+chamfer), -chamfer, -(2*filleting_radius-chamfer+2*chamfer)])
    cylinder_c(chamfer*2, chamfer, res=circle_res_correction(chamfer));
    
    translate([(2*filleting_radius-chamfer+chamfer), -(2*filleting_radius-chamfer), -(2*filleting_radius-chamfer+2*chamfer)])
    cylinder_c(chamfer*2, chamfer, res=circle_res_correction(chamfer));
    
    translate([chamfer, -(2*filleting_radius-chamfer), -(2*filleting_radius-chamfer+2*chamfer)])
    cylinder_c(chamfer*2, chamfer, res=circle_res_correction(chamfer));
        }
        
       
    }
}
module shoulder_base_yoke(filleting_radius)
{

    
    hull() //the bottom part of the yoke
    {
    translate([0, 0, shoulder_max-base_bolt-bolt_head_thick])
    cylinder_c(bolt_head_seat, bolt_head_bezel, res=circle_res_correction(bolt_head_bezel));
    
    translate([bolt_head_bezel, arm_offset-bolt_head_bezel+filleting_radius, shoulder_max-base_bolt-bolt_head_thick+filleting_radius])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));    
        
    translate([bolt_head_bezel, arm_offset-bolt_head_bezel+filleting_radius, shoulder_max-base_bolt-bolt_head_thick-filleting_radius+bolt_head_seat])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, filleting_radius, res=circle_res_correction(filleting_radius));    
    }


    
    
    hull() //the top part of the yoke
    {
    translate([0, 0, shoulder_max-topside_shoulder-bolt_head_seat])
    cylinder_c(bolt_head_seat, bolt_head_bezel, res=circle_res_correction(bolt_head_bezel));
    
    translate([bolt_head_bezel, arm_offset-bolt_head_bezel+filleting_radius, shoulder_max-topside_shoulder-bolt_head_seat/2])
        rotate([0, -90, 0])
        cylinder_c(2*bolt_head_bezel, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));    
    }
    

}
module bolt_head_seat_cutout()
{
    translate([0, 0, bolt_head_seat-bolt_head_thick])
    cylinder_c(bolt_head_thick+break_edge, bolt_head_thick+tolerance, chamfer1=break_edge, chamfer2=-2*break_edge);
    
    translate([0, 0, -break_edge])
    cylinder_c(bolt_head_seat-bolt_head_thick+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);
}
module bolt_head_seat_nut_cutout()
{
    translate([0, 0, bolt_head_seat-bolt_head_thick])
    cylinder_c(bolt_head_thick+break_edge, nut_radius/cos(30)+tolerance, chamfer1=break_edge, chamfer2=-2*break_edge, faces=6);
    
    translate([0, 0, -break_edge])
    cylinder_c(bolt_head_seat-bolt_head_thick+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);   
}
module shoulder_cutouts()
{
    translate([shoulder_width/2-bolt_head_seat, arm_offset, arm_elevation])
    rotate([0, 90, 0])
    bolt_head_seat_cutout();
    
    translate([0, 0, -base_bolt-bolt_head_thick+bolt_head_seat])
    mirror([0, 0, 1])
    bolt_head_seat_cutout();
    
    translate([-shoulder_width/2+bolt_head_seat, arm_offset, arm_elevation])
    rotate([0, -90, 0])
    bolt_head_seat_nut_cutout();
    
    translate([0, 0, shoulder_max-topside_shoulder-bolt_head_seat])
    bolt_head_seat_nut_cutout();
}
module shoulder()
{

    difference()
    {
    union()
        {
    for ( i = [ 0 : 1 ] )
    mirror([i, 0, 0])
    {
    shoulder_arm_yoke(filleting_radius);
    shoulder_body(filleting_radius);
    }
    shoulder_base_yoke(filleting_radius);
        }
    shoulder_cutouts();
    }
}
}
{//effector
module effector_bearing_bezel_cutout()
{
    translate([0, 0, effector_bearing_seat-effector_bearing_thick])
    cylinder_c(effector_bearing_thick+break_edge, effector_bearing_radius+tolerance, chamfer1=break_edge, chamfer2=-2*break_edge);
    
    translate([0, 0, -break_edge])
    cylinder_c(effector_bearing_seat-effector_bearing_thick+2*break_edge, effector_bearing_bore+tolerance, chamfer=-2*break_edge, chamfer2=-2*break_edge);
}
module effector_middle_cutout()
{
    translate([0, 0, effector_middle/2-effector_bearing_thick])
    cylinder_c(effector_bearing_thick+break_edge, effector_bearing_radius+tolerance, chamfer1=break_edge, chamfer2=-2*break_edge);
    
    translate([0, 0, -break_edge])
    cylinder_c(effector_middle/2-effector_bearing_thick+2*break_edge, effector_bearing_bore+tolerance, chamfer=0, chamfer2=-2*break_edge);
}    
    
module effector_arm_center_yoke(thick)
{

    
    for ( i = [ 0 : 1 ] )
    mirror([i,0,0])
    {
    hull()
    {
    translate([gear_width/2+washer, arm_offset, 0])
    rotate([0, 90, 0])
    cylinder_c(bolt_head_seat, thick/2, res=circle_res_correction(thick/2));
        
    translate([gear_width/2+washer+bolt_head_seat/2, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance, -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
    }
    
    hull()
    {
        translate([gear_width/2+washer+bolt_head_seat/2, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance, -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
        
        translate([0, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance, -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
        
        translate([effector_bearing_bezel-bolt_head_seat/2, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance-((gear_width/2+washer+bolt_head_seat/2)-(effector_bearing_bezel-bolt_head_seat/2))*tan(chamfer_angle), -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
        
        translate([0, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance-((gear_width/2+washer+bolt_head_seat/2)-(effector_bearing_bezel-bolt_head_seat/2))*tan(chamfer_angle), -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
    }
    
    hull()
    {
        translate([effector_bearing_bezel-bolt_head_seat/2, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance-((gear_width/2+washer+bolt_head_seat/2)-(effector_bearing_bezel-bolt_head_seat/2))*tan(chamfer_angle), -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
        
       translate([0, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance-((gear_width/2+washer+bolt_head_seat/2)-(effector_bearing_bezel-bolt_head_seat/2))*tan(chamfer_angle), -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
        
        translate([0, 0, -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
        
        translate([effector_bearing_bezel-bolt_head_seat/2, 0, -thick/2])
    cylinder_c(thick, bolt_head_seat/2, res=circle_res_correction(bolt_head_seat/2));
    }
      
    translate([filleting_radius-chamfer+effector_bearing_bezel, arm_offset-effector_bearing_bezel-bolt_head_seat/2-clearance-((gear_width/2+washer+bolt_head_seat/2)-(effector_bearing_bezel-bolt_head_seat/2))*tan(chamfer_angle)-bolt_head_seat/2*tan(chamfer_angle/2)-(filleting_radius-chamfer)*tan(chamfer_angle/2), -thick/2])
    rotate([0, 0, chamfer_angle+90])
    cylinder_c_internal(thick, filleting_radius-chamfer, thick=chamfer, deg=chamfer_angle, res=circle_res_correction(filleting_radius));
    
    translate([gear_width/2+washer, arm_offset-effector_bearing_bezel-clearance, 0])
    rotate([0, 0, 180])
    rotate([0, 90, 0])
    inside_filleted_chamfer(thick, chamfer, filleting_radius);
    }
    
    translate([0, 0, -thick/2])
    cylinder_c(thick, effector_bearing_bezel, res=circle_res_correction(effector_bearing_bezel));
}
module effector_arm_yoke(thick, yoke_width)
{

    difference()
    {
    union()
    {
    hull()
    {
    for ( i = [ 0 : 1 ] )
    mirror([i,0,0])
    {
    translate([gear_width/2+washer, arm_offset-bolt_head_bezel+2*chamfer, 0])
    rotate([180, 0, 0])
    rotate([0, 90, 0])
    cylinder_c(bolt_head_seat, thick/2, res=circle_res_correction(thick/2), deg=180);
        
    translate([gear_width/2+washer+bolt_head_seat-filleting_radius, arm_offset-max(effector_bearing_bezel+clearance, bolt_head_bezel+filleting_radius)-bolt_head_seat, -thick/2])
    cylinder_c(thick, filleting_radius, res=circle_res_correction(filleting_radius));
        
    translate([effector_bearing_bezel-filleting_radius, arm_offset-max(effector_bearing_bezel+clearance, bolt_head_bezel+filleting_radius)-bolt_head_seat-(gear_width/2+washer+bolt_head_seat-effector_bearing_bezel)*tan(chamfer_angle), -thick/2])
    cylinder_c(thick, filleting_radius, res=circle_res_correction(filleting_radius));     
    }
    }
    
    hull()
    {
    for( i = [ 0 : 1 ] )
    mirror([i,0,0])
    {
        translate([effector_bearing_bezel-filleting_radius, arm_offset-bolt_head_bezel-filleting_radius-(gear_width/2+washer+bolt_head_seat-effector_bearing_bezel)*tan(chamfer_angle), -thick/2])
    cylinder_c(thick, filleting_radius, res=circle_res_correction(filleting_radius));  
        
        translate([effector_bearing_bezel-filleting_radius, 0, -thick/2])
        cylinder_c(thick, filleting_radius, res=circle_res_correction(filleting_radius));  
    }
    }
    
    for ( i = [ 0 : 1 ] )
    mirror([i, 0, 0])
    translate([(filleting_radius-chamfer+effector_bearing_bezel), (arm_offset-max(effector_bearing_bezel+clearance, bolt_head_bezel+filleting_radius)-bolt_head_seat-(gear_width/2+washer+bolt_head_seat-effector_bearing_bezel)*tan(chamfer_angle)-(filleting_radius)*tan(chamfer_angle/2)-(filleting_radius-chamfer)*tan(chamfer_angle/2)), -thick/2])
    rotate([0, 0, chamfer_angle+90])
    cylinder_c_internal(thick, filleting_radius-chamfer, thick=chamfer, deg=chamfer_angle, res=circle_res_correction(filleting_radius));
    
    
    translate([0, 0, -thick/2])
    cylinder_c(thick, effector_bearing_bezel, res=circle_res_correction(effector_bearing_bezel));
    }
    
    translate([0, 0, -thick/2-chamfer])
    for ( i = [ 0 : 1 ] )
    mirror([i, 0, 0])
    poly_cylinder_c(
    [
    [gear_width/2+washer-(filleting_radius-chamfer), arm_offset-bolt_head_bezel+2*chamfer, 0],
    [gear_width/2+washer-(filleting_radius-chamfer), arm_offset-max(effector_bearing_bezel+clearance, bolt_head_bezel+filleting_radius), 0],
    [0, arm_offset-bolt_head_bezel+2*chamfer, 0],
    [chamfer/2, arm_offset-max(effector_bearing_bezel+clearance, bolt_head_bezel+filleting_radius)-chamfer-(gear_width/2+washer-chamfer-(filleting_radius-chamfer)-chamfer/2), 0],
    [0, arm_offset-max(effector_bearing_bezel+clearance, bolt_head_bezel+filleting_radius)-chamfer-(gear_width/2+washer-chamfer-(filleting_radius-chamfer)-chamfer/2), 0]
    ],
    thick+2*chamfer, filleting_radius-chamfer, chamfer=2*chamfer, res=circle_res_correction(filleting_radius+chamfer));
    }
}
module effector_hub_yoke(yoke_width)
{

    
    difference()
    {
    for ( i = [ 0 : 1 ] )
    mirror([0, 0, i])
    {
    translate([0, 0, effector_bearing_seat/2+yoke_width])
    effector_arm_yoke(effector_bearing_seat);
    for ( j = [ 0 : 1 ] )
    mirror([j, 0, 0])
    {
    translate([gear_width/2+washer+bolt_head_seat/2, arm_offset-bolt_head_bezel, yoke_width])
    rotate([90, 0, 0])
    inside_filleted_chamfer(bolt_head_seat, chamfer, filleting_radius);
    
    hull()
    {
        translate([gear_width/2+washer, arm_offset-bolt_head_bezel+filleting_radius, yoke_width+effector_bearing_seat-filleting_radius])
        rotate([0, 90, 0])
        cylinder_c(bolt_head_seat, filleting_radius, res=circle_res_correction(filleting_radius));
        
        translate([gear_width/2+washer, arm_offset, yoke_width+effector_bearing_seat-filleting_radius])
        rotate([0, 90, 0])
        cylinder_c(bolt_head_seat, filleting_radius, res=circle_res_correction(filleting_radius));
        
        translate([gear_width/2+washer, arm_offset+bolt_head_bezel-filleting_radius, yoke_width+effector_bearing_seat-filleting_radius-(bolt_head_bezel-filleting_radius)*tan(chamfer_angle)])
        rotate([0, 90, 0])
        cylinder_c(bolt_head_seat, filleting_radius, res=circle_res_correction(filleting_radius));
        
        translate([gear_width/2+washer, arm_offset, 0])
    rotate([0, 90, 0])
    cylinder_c(bolt_head_seat, bolt_head_bezel, res=circle_res_correction(bolt_head_bezel));
    }
}
    }
    
    for ( i = [ 0 : 1 ] )
    mirror([0, 0, i])
    translate([0, 0, -yoke_width-effector_bearing_seat])
    effector_bearing_bezel_cutout();
    
    translate([-gear_width/2-washer, arm_offset, 0])
    rotate([0, -90, 0])
    bolt_head_seat_cutout();
    
    translate([gear_width/2+washer, arm_offset, 0])
    rotate([0, 90, 0])
    bolt_head_seat_nut_cutout();
    }
}
module effector_axle()
{
    //setup for e3d v6.
    
    thread_angle = 40;
    thread_pitch = 1;
    
    notch_radius = 16;
    groove_radius = 12;
    top_notch = 3.7;
    groove = 6;
    bottom_notch = 6;
    
    
    difference()
    {
    union()
    {
    translate([0, 0, -(wall_thick+top_notch+groove+bottom_notch)])
    cylinder_c(wall_thick+top_notch+groove+bottom_notch, notch_radius+wall_thick+chamfer);
    
    translate([0, 0, 2*(effector_height-hotend_height-washer-wall_thick)])
    screw_thread(thread_diameter=effector_bearing_bore*2,threaded_length=3*wall_thick,pitch=thread_pitch,thread_angle=thread_angle,rs=res,cs=1);
    
    translate([0, 0, -break_edge])
    cylinder_c(2*(effector_height-hotend_height)-2*(washer+wall_thick)+break_edge, effector_bearing_bore-tolerance,chamfer1=-2*break_edge, chamfer2=break_edge);
    }
    
    translate([0,0,-(wall_thick+top_notch+groove+bottom_notch)])
    {//groove mount    
    translate([0, 0, -break_edge])
    cylinder_c(bottom_notch+break_edge, notch_radius, chamfer1=-2*break_edge, chamfer2=break_edge);    
        
    translate([0, 0, bottom_notch-break_edge])
    cylinder_c(groove+2*break_edge, groove_radius, chamfer=-2*break_edge); 
      
    translate([0, 0, bottom_notch+groove])
    cylinder_c(top_notch+break_edge, notch_radius, chamfer=break_edge);   
    }
    
    //
    translate([0, 0, bottom_notch+groove+top_notch-(wall_thick+top_notch+groove+bottom_notch)])  
    cylinder_c(10*(effector_height-hotend_height), bowden_radius, chamfer=0);
    
    translate([-break_edge, -2*effector_bearing_bore, bottom_notch+groove+top_notch+wall_thick+washer+2*(effector_height-hotend_height-wall_thick-washer)-(wall_thick+top_notch+groove+bottom_notch)])  
    cube([2*break_edge, 4*effector_bearing_bore, 4*wall_thick]);
    
    translate([-(notch_radius+wall_thick+chamfer), effector_bearing_bore, -(wall_thick+top_notch+groove+bottom_notch)])
    cube([2*(notch_radius+wall_thick+chamfer), 2*(notch_radius+wall_thick+chamfer), bottom_notch+groove+top_notch+wall_thick]);
    
    }

}
module effector_bowden_nut()
{
    hex_nut(2*effector_bearing_bore, hex_radius=effector_bearing_bezel,hex_height=wall_thick+2*chamfer,pitch=thread_pitch,thread_angle,crs=res);
}
module effector_middle()
{
    effector_hub_yoke(effector_middle/2+washer);
}
module effector_outer()
{ 
    
    
    effector_hub_yoke(effector_middle/2+washer+effector_bearing_seat+washer);
}
module effector_inner()
{
    difference()
    {
    union()
    {
    effector_hub_yoke(-2*chamfer, effector_bearing_seat=effector_middle/2+2*chamfer);
    translate([0, 0, -effector_middle/2])
    cylinder_c(effector_middle, effector_bearing_bezel);
    }
    
    for ( i = [ 0 : 1 ] )
    mirror([0, 0, i])
    effector_middle_cutout();   
        
    translate([-gear_width/2-washer, arm_offset, 0])
    rotate([0, -90, 0])
    bolt_head_seat_cutout();
    
    translate([gear_width/2+washer, arm_offset, 0])
    rotate([0, 90, 0])
    bolt_head_seat_nut_cutout();
    }
}
}
{//base/frame/whatever
module base_blank()
{
    filleting_radius = fillet_radius+chamfer+drive_gear_thick; 

    for ( i = [ 0 : 2 ] )
    rotate([0, 0, i*120])
    {
    for ( i = [ 0 : 1 ] )
    mirror([i, 0, 0])
    difference()
    {
    translate(polar(center_distance, -120))
    rotate([0, 0, 30])
    cylinder_c(frame_thick, total_base_diameter, chamfer=chamfer+drive_gear_thick, deg=30);
    
    
    translate(polar(base_cutout_distance, 60))
    translate(polar(center_distance, 240))
    translate([0, 0, -chamfer])
    cylinder_c(frame_thick+2*chamfer, base_cutout_circle, chamfer=-(2*chamfer+drive_gear_thick));
    
    translate(polar(total_base_diameter-filleting_radius, 30+base_cut_angle))
    translate(polar(center_distance, 240))
    rotate([0, 0, -45])
    translate([0, 0, -chamfer])
    cylinder_c_internal(frame_thick+2*chamfer, filleting_radius, chamfer=-(2*chamfer+drive_gear_thick), thick=2*filleting_radius, deg=90);
    
    translate([-total_base_diameter/2-chamfer, -(2*center_distance+2*bearing_bezel)/2, -chamfer])
    cube([total_base_diameter/2, 2*center_distance+2*bearing_bezel, frame_thick+2*chamfer]);
    }
    
    translate([0, center_distance, 0])
    cylinder_c(frame_thick, bearing_bezel+drive_gear_thick, chamfer=chamfer+drive_gear_thick);
   
    translate([0, 0, 0])
    motor_mounts();
    }
    
    
    cylinder_c(frame_thick, base_cutout_distance-center_distance-base_cutout_circle, chamfer=chamfer+drive_gear_thick);
    
 
}
module motor_mounts()
{
    translate(motor_xy)
    rotate([0, 0, -motor_mount_rotation])
    translate([0, -driving_radius, 0])
    {
    hull()
    {
        for ( i = [ 0 : 1 ] )
        mirror([i, 0, 0])
        {
        translate([motor_mount_width-chamfer-filleting_radius+chamfer-drive_gear_thick, 0, 0])
        {
        cylinder_c(frame_thick-(direct_drive == "true" ? 0:drive_gear_thick), filleting_radius+drive_gear_thick, chamfer1=drive_gear_thick+chamfer, chamfer2=(direct_drive == "true" ? drive_gear_thick+chamfer:chamfer), res=circle_res_correction(filleting_radius+drive_gear_thick));
        
        translate([0, driving_radius+motor_mount_width-chamfer-filleting_radius+chamfer-drive_gear_thick, 0])
        cylinder_c(frame_thick-(direct_drive == "true" ? 0:drive_gear_thick), filleting_radius+drive_gear_thick, chamfer1=drive_gear_thick+chamfer, chamfer2=(direct_drive == "true" ? drive_gear_thick+chamfer:chamfer), res=circle_res_correction(filleting_radius+drive_gear_thick));
        }
        }
    }
    
    for ( i = [ 0 : 1 ] )
    mirror([i,0,0])
    translate([(motor_width/2+chamfer+wall_thick+chamfer+drive_gear_thick), driving_radius-fillet_shift, 0])
    translate([filleting_radius-chamfer, fillet_initial_shift, 0])
    rotate([0, 0, 180])
    cylinder_c_internal(frame_thick-(direct_drive == "true" ? 0:drive_gear_thick), filleting_radius-chamfer, chamfer=0, chamfer1=(drive_gear_thick+chamfer),  chamfer2=(direct_drive == "true" ? drive_gear_thick+chamfer:chamfer), thick=fillet_thickness-filleting_radius+chamfer, deg=fillet_degrees);
    
    
    translate([-(accessory_mount)/2, 0, bolt_sleeve])
    rotate([0, 90, 0])
    difference()
    {
    hull()
    {
    translate([0, driving_radius+motor_mount_width+bolt_sleeve+clearance, 0])
    cylinder_c(accessory_mount, bolt_sleeve, res=circle_res_correction(bolt_sleeve));
    
    translate([0, driving_radius, 0])
    cylinder_c(accessory_mount, bolt_sleeve, res=circle_res_correction(bolt_sleeve));
    }
    
    translate([0, driving_radius+motor_mount_width+bolt_sleeve+clearance, -break_edge])
    cylinder_c(accessory_mount+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);
    }
    
    }
}
module motor_hold_tabs(width)
{
    translate([0, 0, -width/2])
    hull()
    {
        translate([0, 0, 0])
        cylinder_c(width, chamfer);
        
        translate([0, min_thick, 0])
        cylinder_c(width, chamfer);
        
        translate([-chamfer, min_thick, 0])
        cylinder_c(width, chamfer);
        
        translate([-chamfer, -chamfer, 0])
        cylinder_c(width, chamfer);
    }
}
module base_cutouts()
{
    for ( i = [ 0 : 2 ] )
    rotate([0, 0, i*120])
    {
    //shoulder pivot
    translate([0, center_distance, 0])
    {
    for ( i = [ 0 : 1 ] )
    translate([0, 0, i*frame_thick])
    mirror([0, 0, i])
    translate([0, 0, -break_edge])
    cylinder_c(bearing_thick+2*break_edge, bearing_radius+tolerance, chamfer=break_edge, chamfer1=-2*break_edge);
    
    translate([0, 0, bearing_thick])
    cylinder_c(frame_thick-2*bearing_thick, bolt_radius+tolerance, chamfer=-(bearing_radius-bolt_radius));
    }
    
    if ( direct_drive == "false" )
    {
    //drive gear
    translate([0, drive_axle_offset, 0])
    {
    translate([0, 0, frame_thick-drive_gear_thick])
    cylinder_c(drive_gear_thick+chamfer, drive_gear_cutouts, chamfer1=chamfer, chamfer2=-2*chamfer, res=circle_res_correction(drive_gear_cutouts*2+2*chamfer));
    
    //drive gear bolts/axles
    translate([0, 0, -break_edge])
    cylinder_c(frame_thick-drive_gear_thick+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);
    }
    }
    
    //mounting hole for bottom plate if there are no geared drive pulleys
    if ( direct_drive == "true" )
    translate([0, 0, -break_edge])
    cylinder_c(frame_thick+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);
    
    //motor_cutouts
    translate(motor_xy)
    rotate([0, 0, -motor_mount_rotation])
    translate([0, -driving_radius, 0])
    translate([0, driving_radius, -chamfer])
    {
    difference()
    {
    poly_cylinder_c(
    [
    [motor_width/2-(filleting_radius-chamfer), -(motor_width/2-(filleting_radius-chamfer)  ), 0],
    [-(motor_width/2-(filleting_radius-chamfer)), -(motor_width/2-(filleting_radius-chamfer)), 0],
    [motor_width/2-(filleting_radius-chamfer), (motor_width/2-(filleting_radius-chamfer)), 0],
    [-(motor_width/2-(filleting_radius-chamfer)), (motor_width/2-(filleting_radius-chamfer)), 0]
    ],
    frame_thick+2*chamfer+(direct_drive == "true" ? drive_gear_thick:0), filleting_radius-chamfer, chamfer1=2*chamfer, chamfer2=drive_gear_thick+2*chamfer);
    
    for ( j = [ 0 : 1 ] )
    rotate([0, 0, j*90])
    for ( i = [ 0 : 1 ] )
    mirror([i,0,0])
    translate([-motor_width/2, 0, frame_thick-(direct_drive == "true" ? 0:drive_gear_thick)-min_thick])
    rotate([90, 0, 0])    
    motor_hold_tabs(motor_width/3);
    }
    
 
    poly_cylinder_c(
    [
    [motor_width/2-(min_thick+clearance)-filleting_radius+chamfer-min_thick, -motor_width/2, 0],
    [-(motor_width/2-(min_thick+clearance)-filleting_radius+chamfer-min_thick), -motor_width/2, 0]
    ],
    frame_thick-(direct_drive == "true" ? 0:drive_gear_thick)-chamfer-min_thick+chamfer, min_thick+clearance, chamfer1=2*chamfer, chamfer2=-(min_thick+clearance));
    
    }
    }
}
module bottom_plate()
{
    difference()
    {
    for ( i = [ 0 : 2 ] )
    rotate([0, 0, i*120])
    {
    translate(polar(drive_axle_offset, 240))
    cylinder_c(wall_thick+2*chamfer, drive_axle_offset*cos(30)*2+bolt_bezel, deg=60);
    
    translate([0, drive_axle_offset, 0])
    cylinder_c(wall_thick+2*chamfer, bolt_bezel);
    }
    
    if ( direct_drive == "false" )
    for ( i = [ 0 : 2 ] )
    rotate([0, 0, i*120])
    translate([0, drive_axle_offset, -break_edge])
    cylinder_c(wall_thick+2*chamfer+2*break_edge, chamfer=-2*break_edge, bolt_radius+tolerance);
    
    if ( direct_drive == "true" )
    translate([0, 0, -break_edge])
    cylinder_c(wall_thick+2*chamfer+2*break_edge, chamfer=-2*break_edge, bolt_radius+tolerance);
    }
    
}
module base()
{ 
   difference()
    {
        base_blank();
        base_cutouts();
        
    }
    

    

}
}
{//drives
module motor_shaft()
{
    difference()
    {
    translate([0, 0, -break_edge])
    cylinder_c(motor_shaft_length+break_edge, motor_shaft_radius, chamfer1=-2*break_edge, chamfer2=break_edge);
        
    translate([-motor_shaft_radius, motor_shaft_radius-motor_key, motor_shaft_length-motor_key_length])
    cube([2*motor_shaft_radius, 2*motor_shaft_radius, motor_key_length]);
    }
}
module direct_drive_pulley()
{
    difference()
    {
    union()
    {
    for ( i  = [ 0 : 1 ] )
    translate([0, 0, i*(motor_shaft_length)])
    cylinder_c(wall_thick, motor_shaft_radius+wall_thick+2*chamfer);
    
    translate([0, 0, wall_thick])
    cylinder_c(motor_shaft_length-wall_thick, motor_shaft_radius+wall_thick, chamfer=-chamfer);
    }
    motor_shaft();
    }
}
module geared_pulley()
{
    difference()
    {
    union()
    {
    gear(reel_teeth, drive_gear_thick, twist=1, chamfer=break_edge);
    translate([0, 0, drive_gear_thick])
    cylinder_c(wall_thick+2*chamfer, root_radius(reel_teeth)-chamfer-break_edge, chamfer=-chamfer);
    translate([0, 0, drive_gear_thick+wall_thick+2*chamfer])
    cylinder_c(wall_thick, root_radius(reel_teeth)-break_edge+chamfer);
    }
    
    for ( i = [ 0 : 1 ] )
    translate([0, 0, i*(drive_gear_thick+wall_thick+2*chamfer+wall_thick)])
    mirror([0, 0, i])
    translate([0, 0, -break_edge])
    cylinder_c(bearing_thick+break_edge+bearing_radius+tolerance, bearing_radius+tolerance, chamfer1=-2*break_edge, chamfer2=bearing_radius+tolerance);
    
    translate([0, 0, -break_edge])
    cylinder_c(drive_gear_thick+wall_thick+2*chamfer+wall_thick+2*break_edge, bolt_radius+tolerance, chamfer=-2*break_edge);
    }
}
module motor_gear()
{
    difference()
    {
    gear(motor_teeth, drive_gear_thick, chamfer=break_edge, twist=1);
    translate([0, 0, -motor_shaft_length+drive_gear_thick+break_edge])
    motor_shaft();
    }
        
}
}

module arm_assembly()
{
    
    echo(home_angle);
    //rotate([0, 0*(90-home_angle)-90, 0])
    
    for ( i = [ 0 : 2 ] )
    rotate([0, 0, 90+i*120])
    translate([center_distance, 0, 0])
    {    
        translate([arm_offset, 0, arm_elevation])
        rotate([0, -extension_angle/2+home_angle, 0])
        rotate([90, 0, 0])
        translate([0, pitch_radius+2*tooth_radius+bearing_bezel+minimum_spacing+extra_space, -gear_width/2])
        mirror([1, 0, 0])
        arm_model();

        rotate([0, 0, -90])
        shoulder();

        translate([-total_reach*cos(home_angle), 0, total_reach*sin(home_angle)])
        rotate([0, 0, -90])
        {
        if ( i == 0 )
        effector_inner();
        if ( i == 1 )
        effector_middle();
        if ( i == 2 )
        effector_outer();
        }
    }
    translate([0, 0, total_reach*sin(home_angle)-effector_height+hotend_height+wall_thick])
    effector_axle();
    
    translate([0, 0, total_reach*sin(home_angle)+effector_height-hotend_height-wall_thick])
    effector_bowden_nut();
}
module base_assembly()
{
    translate([0, 0, -frame_thick-topside_shoulder])
    {
        base();
        
        for ( i = [ 0 : 2 ] )
        rotate([0, 0, i*120])
        {
            if ( direct_drive ==  "true" )
            {
                translate(motor_xy)
                translate([0, 0, frame_thick-2*chamfer-min_thick])
                direct_drive_pulley();
            }
            if ( direct_drive == "false" )
            {
                translate([0, drive_axle_offset, frame_thick-drive_gear_thick+washer])
                geared_pulley();
                translate(motor_xy)
                translate([0, 0, frame_thick-drive_gear_thick+washer])
                motor_gear();
            }
        }
    }
}

module assembly()
{
    arm_assembly();
    base_assembly();
}
//assembly();
//shoulder();               //x3
//arm(0);                   //x3    //drive arm
//arm(1);                   //x3    //driven arm
//effector_outer();         //x1
//effector_middle();        //x1
//effector_inner();         //x1
//base();                   //x1
//bottom_plate();           //x1

//effector_axle();          //x1
//effector_bowden_nut();    //x1
//direct_drive_pulley();    //x3 ONLY FOR DIRECT DRIVE
//geared_pulley();          //x3 ONLY FOR GEARED DRIVE
//motor_gear();             //x3 ONLY FOR GEARED DRIVE

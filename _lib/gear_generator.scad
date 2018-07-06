//TO DO
/*
C/P all the chamfer/resolution stuff from cycloidal gears to involute gears whenever I end up using involutes next and need the new features, can't be stuffed now.
*/

{//gear and rack profile modules
{//gear_profile module
//Meshing gears must match in mm_per_tooth, pressure_angle, and twist,
//and be separated by the sum of their pitch radii, which can be found with pitch_radius().
module gear_profile (
    number_of_teeth = 10,   //total number of teeth around the entire perimeter
	mm_per_tooth    = mm_per_tooth,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	teeth_to_hide   = 0,    //number of teeth to delete to make this only a fraction of a circle
	pressure_angle  = pressure_angle,   //Controls how straight or bulged the tooth sides are. In degrees.
	clearance       = 0.0,  //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
	backlash        = 0.0,   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
    res = 0
) 
{
    resolution = res == 0 ? tooth_height(mm_per_tooth)/pi : res;
    segments = tooth_height(mm_per_tooth)/resolution;
	pi = 3.1415926;
	p  = mm_per_tooth * number_of_teeth / pi / 2;  //radius of pitch circle
	c  = p + mm_per_tooth / pi - clearance;      //radius of outer circle
	b  = p*cos(pressure_angle);                    //radius of base circle
	r  = p-(c-p)-clearance;                        //radius of root circle
	t  = mm_per_tooth/2-backlash/2;                //tooth thickness at pitch circle
	k  = -iang(b, p) - t/2/p/pi*180; 
    {             //angle to where involute meets base circle on each side of tooth
		difference() {
			for (i = [0:number_of_teeth-teeth_to_hide-1] )
				rotate([0,0,i*360/number_of_teeth])
						intersection()
                            {
                                polygon(
                                    points=[
                                        [0, 0],
                                        polar(r, -181/number_of_teeth),
                                        polar(r, r<b ? k : -181/number_of_teeth),
                                
                                        for ( i = [ 0 : segments ] )
                                            q7(i/segments, r, b, c, k, 1),
                                        
                                        polar(c, 181/number_of_teeth)
                                        ]
                                       );
                                mirror([1,0,0]) polygon(
                                    points=[
                                        [0, 0],
                                        polar(r, -181/number_of_teeth),
                                        polar(r, r<b ? k : -181/number_of_teeth),
                                        
                                        for ( i = [ 0 : segments ] )
                                            q7(i/segments, r, b, c, k, 1),
                                        
                                        polar(c, 181/number_of_teeth)
                                        ]
                                       );
                            }
		}
	}
};	

//these 4 functions are used by gear
function polar(r,theta)   = r*[sin(theta), cos(theta)];                            //convert polar to cartesian coordinates
function iang(r1,r2)      = sqrt((r2/r1)*(r2/r1) - 1)/3.1415926*180 - acos(r1/r2); //unwind a string this many degrees to go from radius r1 to radius r2
function q7(f,r,b,r2,t,s) = q6(b,s,t,(1-f)*max(b,r)+f*r2);                         //radius a fraction f up the curved side of the tooth 
function q6(b,s,t,d)      = polar(d,s*(iang(b,d)+t));                              //point at radius d on the involute curve
}
{//cycloidal gear profile
module c_gear_profile(num_teeth, tooth_radius, start=0, shown_teeth=0, res=0, slices=0, tolerance=0)
{
    show_teeth = shown_teeth == 0 ? 2*num_teeth+2*start : shown_teeth;
    tolerance=tolerance;
    pitch_radius = cycloid_pitch_radius (num_teeth, tooth_radius);
    root_radius = pitch_radius-tooth_radius;
    crest_radius = pitch_radius+tooth_radius;
    
    resolution = res==0 ? (slices==0 ? 2*pi*tooth_radius:slices) : res;
    //creates a new face every XX (res) mm along the gear surface. It's an approximation. Bite me, I'm lazy.
    function polar(theta, r)
        = r*[sin(theta), cos(theta)];
    
    function tooth_number(i)
        = floor((i+segments_per_tooth/2-1)/(segments_per_tooth)) == -1 ? 0 : floor((i+segments_per_tooth/2-1)/(segments_per_tooth));
        
    function tooth_segment(i)
        =(i+segments_per_tooth/2-1)%(segments_per_tooth)+1-segments_per_tooth/2;
    
    
        //generates epicycloid
    function tooth(tooth_r, i)
        = polar(tooth_segment(i)*arc_segment(tooth_r)+tooth_number(i)*180/num_teeth, pitch_radius+tooth_r)+polar(i*tooth_arc+i*arc_segment, tooth_r);
    
        //generates hypocyloid
    function root(tooth_r, i)
        = polar(tooth_segment(i)*arc_segment(tooth_r)+tooth_number(i)*180/num_teeth, pitch_radius-tooth_r)-polar(-(i*tooth_arc-i*arc_segment), tooth_r);
    
        //selects appropriate curve
    function alternator (i)
        = i == -segments_per_tooth/2 ? tooth(tooth_radius-tolerance/2, i) : floor(((i+segments_per_tooth/2-1)/(segments_per_tooth))%2) == 0 ? tooth(tooth_radius-tolerance/2, i) : root(tooth_radius+tolerance/2, i); 
        
    approx_arc_segment = (resolution/(2*pi*pitch_radius)*360);
    arc_segment=(90/num_teeth)/ceil((90/num_teeth)/approx_arc_segment);
    segments_per_tooth = (360/(num_teeth*2)/arc_segment); 
    tooth_arc = ((arc_segment*pitch_radius)/tooth_radius);
    
    function arc_segment(tooth_r)
        =tooth_r/pitch_radius*360/segments_per_tooth;
    

    
    
    points = [for ( i = [-segments_per_tooth/2+(start)*(segments_per_tooth*2):(segments_per_tooth*(show_teeth+2*start))-segments_per_tooth/2]) alternator(i)];
    
    polypoints = show_teeth-2*start == 2*num_teeth ? points : concat([[0,0]], points, [[0,0]]);
    polygon(polypoints);
}
}
{//rack_profile module
//a rack, which is a straight line with teeth (the same as a segment from a giant gear with a huge number of teeth).
//The "pitch circle" is a line along the X axis.
module rack_profile (
	mm_per_tooth    = 10,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 10,   //total number of teeth along the rack
	height          = 20,   //height of rack in mm, from tooth top to far side of rack.
	pressure_angle  = 28,   //Controls how straight or bulged the tooth sides are. In degrees.
	backlash        = 0.0   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
) {
	pi = 3.1415926;
	a = mm_per_tooth / pi; //addendum
	t = a*tan(pressure_angle);         //tooth side is tilted so top/bottom corners move this amount
		for (i = [0:number_of_teeth-1] )
			translate([i*mm_per_tooth,0,0])
                intersection()
                    {
                        polygon(
                            points=[
                                [-mm_per_tooth * 3/4, a-height],
                                [-mm_per_tooth * 3/4 - backlash,     -a],
                                [-mm_per_tooth * 1/4 + backlash - t, -a],
                                [-mm_per_tooth * 1/4 + backlash + t,  a],
                                [ mm_per_tooth * 3/4 + backlash,     -a],
                                [ mm_per_tooth * 3/4, a-height]
                                   ]
                               );
                        polygon(
                            points=[
                                [ mm_per_tooth * 1/4 - backlash - t,  a],
                                [ mm_per_tooth * 1/4 - backlash + t, -a],
                                [ mm_per_tooth * 3/4 + backlash,     -a],
                                [ mm_per_tooth * 3/4, a-height],
                                [-mm_per_tooth * 3/4, a-height],
                                [-mm_per_tooth * 3/4 - backlash,     -a]
                                   ]
                               );
                    }
};	
}
}
{//gear analysis for meshing
//These 5 functions let the user find the derived dimensions of the gear.
//A gear fits within a circle of radius outer_radius, and two gears should have
//their centers separated by the sum of their pictch_radius.
function diametral_pitch (mm_per_tooth=mm_per_tooth) 
    = pi / mm_per_tooth;         //tooth density expressed as "diametral pitch" in teeth per millimeter
function module_value    (mm_per_tooth=mm_per_tooth) 
    = mm_per_tooth / pi;                //tooth density expressed as "module" or "modulus" in millimeters
function pitch_radius    (number_of_teeth=11, mm_per_tooth=mm_per_tooth) = mm_per_tooth * number_of_teeth / pi / 2;
function cycloid_pitch_radius   (num_teeth, tooth_radius=tooth_radius)
    =2*num_teeth*tooth_radius;
function outer_radius    (number_of_teeth=11, mm_per_tooth=mm_per_tooth)    //The gear fits entirely within a cylinder of this radius.
	= mm_per_tooth*(1+number_of_teeth/2)/pi;   
function tooth_height (mm_per_tooth=mm_per_tooth) // tells the height of a rack's teeth
    =2*mm_per_tooth/pi;
function root_radius    (number_of_teeth=11, mm_per_tooth=mm_per_tooth)
    =outer_radius(number_of_teeth, mm_per_tooth)-tooth_height(mm_per_tooth);
function pinion_offset (rack_thickness=rack_thickness, mm_per_tooth=mm_per_tooth) //offsets the pinion correctly onto the rack assuming both have their bottoms touching the same axis
    =rack_thickness-3/4*tooth_height(mm_per_tooth);
}
{//rack and pinion modules
{//rack
module rack
(numteeth=10, mm_per_tooth=mm_per_tooth, width=gear_width, thick=rack_thickness, pressure_angle=pressure_angle, angle=twist, rotation=[0,0,0], shift=[0,0,0], secondary_rotation=[0,0,0])
{   
    translate([0, 0, width])
    mirror([0, 0, 1])  
    multmatrix([[ 1, 0, 2*mm_per_tooth*twist/gear_width, 0 ]])
    linear_extrude(height=gear_width/2, center=false, convexity=10)
    translate([mm_per_tooth*3/4, rack_thickness-tooth_height()/2, width/2])
            rack_profile(mm_per_tooth,numteeth,thick, pressure_angle);
    
    multmatrix([[ 1, 0, 2*mm_per_tooth*twist/gear_width, 0 ]])
    linear_extrude(height=gear_width/2, center=false, convexity=10)
    translate([mm_per_tooth*3/4, rack_thickness-tooth_height()/2, width/2])   
            rack_profile(mm_per_tooth,numteeth,thick, pressure_angle);
};
}

{//gear
module gear
(numteeth, width=gear_width, mm_per_tooth=mm_per_tooth, twist=gear_twist, helix=gear_helix, pressure_angle=pressure_angle, chamfer=chamfer, angle=45, chamfer1=0, angle1=45, chamfer2=0, angle2=45, backlash=0, clearance=0, scaling=1, res=0, middle_break=0)
{
    
        if ( helix == 2 )
        {
            for ( i = [ 0 : 1 ] )
            translate([0, 0, gear_width/2])
            mirror([0, 0, i])
            {
            translate([0, 0, gear_width/2-chamfer])
            mirror([0, 0, 1])
            linear_extrude(height=width/2-chamfer-middle_break/2, center=false, convexity=10, twist=twist*360/numteeth, scale=scaling)
                gear_profile(mm_per_tooth=mm_per_tooth, number_of_teeth=numteeth, teeth_to_hide=0, pressure_angle=pressure_angle, backlash=backlash, clearance=clearance, res=res);
            
            translate([0, 0, gear_width/2-chamfer])
            linear_extrude(height=chamfer, center=false, convexity=10, twist=0, scale=(outer_radius(numteeth)-chamfer)/outer_radius(numteeth))
            gear_profile(mm_per_tooth=mm_per_tooth, number_of_teeth=numteeth, teeth_to_hide=0, pressure_angle=pressure_angle, backlash=backlash, clearance=clearance, res=res);
                
                rotate([0, 0, -360/numteeth*twist])
                linear_extrude(height=middle_break/2, center=false, convexity=10, twist=0, scale=scaling)
                gear_profile(mm_per_tooth=mm_per_tooth, number_of_teeth=numteeth, teeth_to_hide=0, pressure_angle=pressure_angle, backlash=backlash, clearance=clearance, res=res);
            }
        }
        if ( helix == 1 )
        {
            translate([0, 0, chamfer])
            linear_extrude(height=width-2*chamfer, center=false, convexity=10, twist=twist*360/numteeth, scale=scaling)
                gear_profile(mm_per_tooth=mm_per_tooth, number_of_teeth=numteeth, teeth_to_hide=0, pressure_angle=pressure_angle, backlash=backlash, clearance=clearance, res=res);         
            for ( i = [ 0 : 1 ] )
            translate([0, 0, i*(gear_width-2*chamfer)+chamfer])
            rotate([0, 0, -i*360/numteeth*twist])
            mirror([0, 0, i-1])
            linear_extrude(height=chamfer, center=false, convexity=10, twist=0, scale=(outer_radius(numteeth)-chamfer)/outer_radius(numteeth))
            gear_profile(mm_per_tooth=mm_per_tooth, number_of_teeth=numteeth, teeth_to_hide=0, pressure_angle=pressure_angle, backlash=backlash, clearance=clearance, res=res);
        }
        
        
};

module c_gear (num_teeth, width=gear_width, tooth_radius=tooth_radius, twist=gear_twist, helix=gear_helix, hide_teeth=0, chamfer=0, angle=45, chamfer1=0, angle1=45, chamfer2=0, angle2=45, res=0, slices=0, tolerance=0, scaling=1, start=0, shown_teeth=0)
{
    difference()
    {
        if ( helix == 2 )
        {
                translate([0, 0, width])
                mirror([0, 0, 1])  
                linear_extrude(height=width/2, center=false, convexity=10, twist=twist*360/num_teeth, slices=(res==0 ? (slices==0 ? 2*pi*tooth_radius:slices) : ceil(width/res/2)), scale=scaling)
                    c_gear_profile(num_teeth, tooth_radius, hide_teeth, res=res, slices=slices, tolerance=tolerance, start=start, shown_teeth=shown_teeth);
                
                linear_extrude(height=width/2, center=false, convexity=10, twist=twist*360/num_teeth, slices=(res==0 ? (slices==0 ? 2*pi*tooth_radius:slices) : ceil(width/res/2)), scale=scaling)
                    c_gear_profile(num_teeth, tooth_radius, hide_teeth, res=res, slices=slices, tolerance=tolerance, start=start, shown_teeth=shown_teeth);  
        }
        
        if ( helix == 1 )
        { 
               linear_extrude(height=width, center=false, convexity=10, twist=twist*360/num_teeth, slices=(res==0 ? (slices==0 ? 2*pi*tooth_radius:slices) : ceil(width/res)), scale=scaling)
                    c_gear_profile(num_teeth, tooth_radius, hide_teeth, res=res, slices=slices, tolerance=tolerance, start=start, shown_teeth=shown_teeth);   
        }
        
        rotate_extrude($fn=ceil(2*pi*(cycloid_pitch_radius(num_teeth)+2*tooth_radius)/res))
            {
                chamfer1h = tan(angle1)*chamfer1;
                chamfer2h = tan(angle2)*chamfer2;
                chamferh = tan(angle)*chamfer;
                
                intersection()
                {
                    union()
                    {
                        translate([cycloid_pitch_radius(num_teeth, tooth_radius)+2*tooth_radius, 0, 0])
                        polygon([ 
                        chamfer == 0 ? [chamfer1, -chamfer1h]:[chamfer, -chamferh], 
                        chamfer == 0 ? [-chamfer1, -chamfer1h]:[-chamfer, -chamfer],
                        chamfer == 0 ? [-chamfer1, 0]:[-chamfer, 0], 
                        chamfer == 0 ? [0, chamfer1h]:[0, chamferh], 
                        chamfer == 0 ? [chamfer1, chamfer1h]:[chamfer, chamferh] ]);
                        
                        translate([cycloid_pitch_radius(num_teeth, tooth_radius)+2*tooth_radius, width, 0])mirror([0,1,0])
                        polygon([ 
                        chamfer == 0 ? [chamfer2, -chamfer2h]:[chamfer, -chamferh], 
                        chamfer == 0 ? [-chamfer2, -chamfer2h]:[-chamfer, -chamfer], 
                        chamfer == 0 ? [-chamfer2, 0]:[-chamfer, 0], 
                        chamfer == 0 ? [0, chamfer2h]:[0, chamferh], 
                        chamfer == 0 ? [chamfer2, chamfer2h]:[chamfer, chamferh] ]);
                    }
                    
                }
            }  
    }
}
}
}//

/*
chamfer=2;
include <gear_settings.scad>
pi=3.141592;
{//gear settings
//  mm_per_tooth = 10;
//  rack_thickness = 20;
  gear_helix = 2;
  gear_twist = 1.25;
//  gear_width = 20;
  pressure_angle = 30;    
}
gear(10, middle_break=1);
//c_gear_profile(10, 4, tolerance=1, start=0.25, shown_teeth=1, res=0.1);
//"shown_teeth" counts roots as teeth too
//c_gear(10, helix=2, res=1, hide_teeth=1, tolerance=1);
*/

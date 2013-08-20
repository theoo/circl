radius = 200;
pieces = 16;
logo_height = 50;
extracted_pieces = 1;
extracted_pieces_distance = 100;
angle = 0;

module circl()
{

	difference() {

		union() {
			for (i = [1:pieces - extracted_pieces]) {
				rotate(i * 360/pieces, [0,0,1])
					translate([radius,0,logo_height / 2])
						tooth(logo_height);
			}
		
			for (i = [1:extracted_pieces]) {
				rotate(i * 360/pieces + ((pieces - extracted_pieces) * 360/pieces), [0,0,1])
					translate([radius + extracted_pieces_distance,0,logo_height / 2])
					tooth(logo_height);
			}

			difference() {
				cylinder(h = logo_height, r1 = radius + 2, r2 = radius + 2, $fn=200);
				for (i = [1:extracted_pieces]) {
					rotate(i * 360/pieces + ((pieces - extracted_pieces) * 360/pieces), [0,0,1])
						translate([radius,0,logo_height / 2])
							tooth(logo_height + 2, 2.2, 2.2);
				}
			}	
		}

		translate([0,0,-1])
			cylinder(h = logo_height + 2, r1 = 125, r2 = 125, $fn=200);	
	}
}

module tooth(thickness, weight=1, height=1) 
{	
	rotate(270) {
		difference() {
			linear_extrude(height = thickness, center = true, convexity = 10, twist = 0)
				polygon(points=[ [15*weight,-80*height],
								[25*weight,0*height],
								[15*weight,25*height],
								[-15*weight,25*height],
								[-25*weight,0*height],
								[-15*weight,-80*height]]);
			translate([0,30,28])
				rotate(75, [1,0,0])
					cube(size = [50,20,60], center = true);

			translate([0,30,-28])
				rotate(285, [1,0,0])
					cube(size = [50,20,60], center = true);
			
		}
	}
}

circl();


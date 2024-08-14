module main
import os
import math
import gfx

////////////////////////////////////////////////////////////////////////////////////////
// Comment out lines in array below to prevent re-rendering every scene.
// If you create a new scene file, add it to the list below.
//
// NOTE: **BEFORE** you submit your solution, uncomment all lines, so
//       your code will render all the scenes!

const (
    scene_filenames = [
        'P02_00_sphere',
        'P02_01_sphere_ambient',
        'P02_02_sphere_room',
        'P02_03_quad',
        'P02_04_quad_room',
        'P02_05_ball_on_plane',
        'P02_06_balls_on_plane',
        'P02_07_reflections',
        'P02_08_antialiased',
        'P02_09_planar_circle',
        'P02_10_direction_ball_on_plane'
        'P02_11_background_gradient'
        'P02_12_background_gradient_2'
    ]
)


////////////////////////////////////////////////////////////////////////////////////////
// module aliasing to make code a little easier to read
// ex: replacing `gfx.Scene` with just `Scene`

type Point     = gfx.Point
type Vector    = gfx.Vector
type Direction = gfx.Direction
type Normal    = gfx.Normal
type Ray       = gfx.Ray
type Color     = gfx.Color
type Image     = gfx.Image

type Intersection = gfx.Intersection
type Surface      = gfx.Surface
type Scene        = gfx.Scene
type Shape = gfx.Shape
type LightType = gfx.LightType



////////////////////////////////////////////////////////////////////////////////////////
//functions to implement

fn intersect_ray_surface(surface Surface, ray Ray) Intersection {
    t_min := ray.t_min
    t_max := ray.t_max
    if surface.shape == Shape.sphere {

        d := ray.d
        a := d.as_vector().length_squared()
        e_sub_c := surface.frame.o.vector_to(ray.e)
        b := (d.scale(2.0)).dot(e_sub_c)
        c :=  e_sub_c.length_squared() - math.pow(surface.radius, 2)

        determinant := b*b - 4*a*c 

        if determinant >= 0 {

            sqrt_determinant := math.sqrt(determinant)
            t_1 := (b*-1 - sqrt_determinant) / (2*a)
            t_2 := (b*-1 + sqrt_determinant) / (2*a)

            //if t_1 is a valid intersection
            if t_1 >= t_min && t_1 <= t_max {

                intersection_1 := ray.at(t_1)
                //find normal of intersection
                n:= surface.frame.o.direction_to(intersection_1)
                //create intersection frame using n as z
                inter_frame := gfx.frame_oz(intersection_1, n)
                
                return Intersection {
                    frame: inter_frame
                    surface: surface
                    distance: ray.e.distance_to(intersection_1)
                }
            }
            else if t_2 <= t_max && t_2 >= t_min {

                intersection_2 := ray.at(t_2)
                n:= surface.frame.o.direction_to(intersection_2)
                //create intersection frame using n as z
                inter_frame := gfx.frame_oz(intersection_2, n)
                
                return Intersection {
                    frame: inter_frame
                    surface: surface
                    distance: ray.e.distance_to(intersection_2)
                }
            }
            
        }
        else {
            return gfx.no_intersection
        }

        
    }
    else if surface.shape == Shape.quad {
        
        //determine center of the shape
       center := surface.frame.o 
       //use the z direction as the normal
       normal := surface.frame.z
       //variables to store values from the ray 
       ray_start := ray.e
       ray_direction := ray.d

        if ray_direction.dot(normal) != 0 {
            
            t := (((ray_start.vector_to(center))).dot(normal))/(ray_direction.dot(normal))

            if (t >= t_min && t <= t_max) {

               intersection := ray.at(t)
               dist := (intersection.vector_to(center)).linf_norm()
               
               
               if dist < surface.radius {
                    //create inter frame
                    
                    inter_frame:= gfx.frame_oz(intersection, normal)
                    return Intersection {
                        frame : inter_frame
                        surface : surface
                        distance : ray.e.distance_to(intersection)
                    }
               }
               else {
                return gfx.no_intersection
               }
            }
            else {
                return gfx.no_intersection
            }
        }
    }
    //ELECTIVE 
    //add a new simple shape, planar circle
        else if surface.shape == Shape.circle {
            //determine center of the shape
            center := surface.frame.o 
            //use the z direction as the normal
            normal := surface.frame.z
            //variables to store values from the ray 
            ray_start := ray.e
            ray_direction := ray.d

            if ray_direction.dot(normal) != 0 {
                
                t := (((ray_start.vector_to(center))).dot(normal))/(ray_direction.dot(normal))

                if (t >= t_min && t <= t_max) {

                intersection := ray.at(t)
                dist := (intersection.vector_to(center)).l2_norm()
                
                
                if dist < surface.radius {
                        //create inter frame
                        
                        inter_frame:= gfx.frame_oz(intersection, normal)
                        return Intersection {
                            frame : inter_frame
                            surface : surface
                            distance : ray.e.distance_to(intersection)
                        }
                }
                else {
                    return gfx.no_intersection
                }
                }
                else {
                    return gfx.no_intersection
                }
            }

            else {
                return gfx.no_intersection
            }
    }
    
    
    return gfx.no_intersection
}

// Determines if given ray intersects any surface in the scene.
// If ray does not intersect anything, null is returned.
// Otherwise, details of first intersection are returned as an `Intersection` struct.
fn intersect_ray_scene(scene Scene, ray Ray) Intersection {
    mut closest := gfx.no_intersection  // type is Intersection

    for s in scene.surfaces {
         mut inter := intersect_ray_surface(s,ray)
         //if an intersection is found
        if (inter != gfx.no_intersection) {
            if  inter.distance < closest.distance {
                //update closest intersection
                closest = inter 
            }
        }
    }

    return closest  // return closest intersection
}


// Computes irradiance (as Color) from scene along ray
fn irradiance(scene Scene, ray Ray) Color {
    background := scene.background_color
    //get intersection 
   
    inter := intersect_ray_scene(scene, ray)
    //if no hit return background intensity
    if inter.miss(){
        //CREATIVE ELEMENT background gradient 
        if scene.background_grad_start != scene.background_grad_end {
            //t represent scale of end color
            t := 0.5 * (-ray.d.y + 1.0)
          
            //contributions of each color to gradient color
            //made it subtracted from 0.8 because i felt like the starting colors contribution was too large over a small space
            start_comp := scene.background_grad_start.scale(0.8 - t)
            end_comp := scene.background_grad_end.scale(t)
            return start_comp.add(end_comp)
        }
        else {
             return background
        }
       
    }
    
    inter_point := inter.frame.o
    //useful things i want defined as variables 
    ambient := scene.ambient_color
    lights := scene.lights
    material := inter.surface.material
    //normal to intersection point
    n := inter.frame.z
    v := (inter_point.vector_to(ray.e)).normalize()
    mut kd := material.kd
    
    mut accum := ambient.mult(material.kd)

    for l in lights {
        s := l.frame.o
        //ELECTIVE
        //add different types of light sources 
        //defaults to point light
        //compute light direction 
        mut l_dir := inter_point.direction_to(s)
        //compute light response 
        mut l_rep := l.kl.scale(f64(1.0/f64(s.distance_squared_to(inter_point))))
        if l.l_type == LightType.direction {
             //compute light direction 
           l_dir = inter_point.direction_to(s)
            //compute light response 
            l_rep = Color {math.clamp(l.kl.r, 0.0 ,1.0),math.clamp(l.kl.g, 0.0 ,1.0),math.clamp(l.kl.b, 0.0 ,1.0)}
        }
        
        n_dot_l := n.dot(l_dir)
        
        shadow_ray := Ray {e:inter.frame.o, d: l_dir, t_max: inter_point.distance_to(s)}
        shadow_intersection := intersect_ray_scene(scene, shadow_ray)
        mut visible := 1
        if shadow_intersection.hit() && shadow_intersection.distance < inter_point.distance_to(s){
            
            visible = 0
        }
    
        //compute the diffuse component
       
        diffuse := material.kd
        //calculate the specular component   
        h := (l_dir.as_vector().add(v)).normalize()
        
        n_dot_h := n.dot(h)
        //calculate specular component 
        //switch math.pow and math.max
        //scale material ks first then multiply by l_rep
        
        specular:= (material.ks.scale(math.max(0.0, f64(math.pow(n_dot_h, material.n)))))
        accum += diffuse.add(specular).mult(l_rep).scale(visible*n_dot_l)

    }
    // //test if material is reflective 
    if material.kr != gfx.black {
        
        r_dir := v.negate().add(n.scale((2*v.dot(n))))
        r := Ray {e: inter.frame.o d: r_dir.as_direction()}
        accum += material.kr.mult(irradiance(scene, r))

    }
    return accum
}

// Computes image of scene using basic Whitted raytracer.
fn raytrace(scene Scene) Image {
    mut image := gfx.Image.new(scene.camera.sensor.resolution)

    //check if there is no anti-aliasing (ie if sameples is more than 1)
    //important values i just want as variables 
    camera_center := scene.camera.frame.o 
    camera_x := scene.camera.frame.x
    camera_y := scene.camera.frame.y
    camera_z := scene.camera.frame.z
    d := scene.camera.sensor.distance
    w := scene.camera.sensor.resolution.width
    h := scene.camera.sensor.resolution.height
    samples := scene.camera.sensor.samples
    subpixel_factor := 1.0/f64(samples)//basically how much to increment through the individual pixels
    if samples == 1 {

        for y in 0 .. h {
            for x in 0 .. w {
                //compute ray-camera paramters 
                u := f64(x+0.5)/f64(w)
                v := 1.0-f64(y+0.5)/f64(h)
                //compute the ray through the pixel sample 
                //q is the point of intersection 
                q := camera_center.add(camera_x.scale((u-0.5)*w)).add(camera_y.scale((v-0.5)*h)).sub(camera_z.scale(d*h))
                //determine camera ray 
                //essentially just ray from o to q 
                mut camera_ray := camera_center.ray_to(q)
                //determine color using irradiance function 
                c := irradiance(scene, camera_ray)
                image.set_xy(x,y,c)
            }
        }
    }
    //else if there is anti-aliasing 
    else {
         for y in 0 .. h {
            for x in 0 .. w {
                //initialize accumulated color to black
                mut accum := gfx.black
                for y_sample in 0 .. samples {
                    for x_sample in 0 .. samples {
                        //compute viewing direction based on pixel and subpixel 
                        mut u := f64(x+(x_sample+0.5)*subpixel_factor)/f64(w)
                        
                        mut v := 1.0-f64(y+(y_sample+0.5)*subpixel_factor)/f64(h)
                      
                        //q is the point of intersection 
                        mut q := camera_center.add(camera_x.scale((u-0.5)*w)).add(camera_y.scale((v-0.5)*h)).sub(camera_z.scale(d*h))
                        //determine camera ray 
                        //essentially just ray from o to q 
                        mut camera_ray := camera_center.ray_to(q)
                        //accumulate result in color 
                        accum = accum.add(irradiance(scene, camera_ray))
                    }
                }
                
                image.set_xy(x, y, accum.scale(1.0/f64(samples*samples)))
            }
         }
    }
    return image
}


fn main() {
    // Make sure images folder exists, because this is where all generated images will be saved
    if !os.exists('output') {
        os.mkdir('output') or { panic(err) }
    }

    for filename in scene_filenames {
        println('Rendering ${filename}...')
        scene := gfx.scene_from_file('scenes/${filename}.json')!
        image := raytrace(scene)
        image.save_png('output/${filename}.png')
    }


    println('Done!')
}

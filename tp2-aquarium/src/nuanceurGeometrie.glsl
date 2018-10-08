#version 410

const float M_PI = 3.14159265358979323846;	// pi
const float M_PI_2 = 1.57079632679489661923;	// pi/2


layout(triangles) in;
layout(triangle_strip, max_vertices = 6) out;



in Attribs {
   vec4 couleur; 

   float clipDistanceDragage;
   float clipDistanceRayonsX;

} AttribsIn[];


out Attribs {
   vec4 couleur;
   
} AttribsOut;





void main( void )
{
   // transformation standard du sommet
  

   
   // Mettre un test bidon afin que l'optimisation du compilateur n'élimine l'attribut "planDragage".
   // Mettre un test bidon afin que l'optimisation du compilateur n'élimine l'attribut "planRayonsX".
   // Vous ENLEVEREZ ce test inutile!
 

   for ( int i = 0 ; i < gl_in.length() ; ++i )
   {  
      
      gl_ViewportIndex = 0;
      gl_Position = gl_in[i].gl_Position;
      AttribsOut.couleur = AttribsIn[i].couleur;
      gl_ClipDistance [0] = AttribsIn[i].clipDistanceDragage;
      gl_ClipDistance [1] = AttribsIn[i].clipDistanceRayonsX;
      EmitVertex();
   }
   EndPrimitive();

   
   for ( int i = 0 ; i < gl_in.length() ; ++i )
   {
     
      gl_ViewportIndex = 1;
      gl_Position = gl_in[i].gl_Position;
      AttribsOut.couleur = AttribsIn[i].couleur;
      gl_ClipDistance [0] = -AttribsIn[i].clipDistanceDragage;
      gl_ClipDistance [1] = AttribsIn[i].clipDistanceRayonsX;
      EmitVertex();
   }
   EndPrimitive();
}

#version 410

uniform int attEloignement;
const float debAttenuation = 30.0;
const float finAttenuation = 50.0;

in Attribs {
   vec4 couleur;
} AttribsIn;

out vec4 FragColor;

vec4 FragColorBlue=vec4(0.0,0.0,1.0,1.0);
vec4 FragColorGreen=vec4(0.0,1.0,0.0,1.0);
vec4 FragColorFront = vec4( vec3(gl_FragCoord.z ), 1.0 );
vec4 FragColorBack = vec4( vec3(gl_FragCoord.w), 1.0 );
vec4 FragColorFish=vec4(0.0,0.0,1.0,1.0);
vec4 mix( vec4 c1, vec4 c2, float fact ) { return c1*(1-fact) + c2*fact; }

void main( void )
{
   // la couleur du fragment est la couleur interpolée
   FragColor = AttribsIn.couleur;
   
//   attEloignement=1;
   // atténuer selon la profondeur
   if ( attEloignement == 1 )
  {
      // Mettre un énoncé bidon afin que l'optimisation du compilateur n'élimine l'attribut "attEloignement".
      // Vous ENLEVEREZ ce test inutile!
      if ( FragColor.x < -10000.0 ) discard;
 
      // Obtenir la distance à la caméra du sommet dans le repère de la caméra
      float dist = gl_FragCoord.z / gl_FragCoord.w;
      //float dist = - (matrVisu * matrModel * Vertex) .z;

	// Obtenir un facteur d'interpolation entre 0 et 1
      float factDist = smoothstep(debAttenuation,finAttenuation,dist);
      // Modifier la couleur du fragment en utilisant ce facteur
      // ...
      FragColor.xyz*=factDist;
      FragColor = mix(FragColor, vec4(0.0, 1.0, 1.0, 1.0),dist );
      
   }
   
 
 
}

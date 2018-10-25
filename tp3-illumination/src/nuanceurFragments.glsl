#version 410

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
   vec4 ambient;
   vec4 diffuse;
   vec4 specular;
   vec4 position[2];      // dans le repère du monde
   vec3 spotDirection[2]; // dans le repère du monde
   float spotExponent;
   float spotAngleOuverture; // ([0.0,90.0] ou 180.0)
   float constantAttenuation;
   float linearAttenuation;
   float quadraticAttenuation;
} LightSource;

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
   vec4 emission;
   vec4 ambient;
   vec4 diffuse;
   vec4 specular;
   float shininess;
} FrontMaterial;

// Définition des paramètres globaux du modèle de lumière
layout (std140) uniform LightModelParameters
{
   vec4 ambient;       // couleur ambiante
   bool localViewer;   // observateur local ou à l'infini?
   bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

layout (std140) uniform varsUnif
{
   // partie 1: illumination
   int typeIllumination;     // 0:Gouraud, 1:Phong
   bool utiliseBlinn;        // indique si on veut utiliser modèle spéculaire de Blinn ou Phong
   bool utiliseDirect;       // indique si on utilise un spot style Direct3D ou OpenGL
   bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le débogage)
   // partie 3: texture
   int texnumero;            // numéro de la texture appliquée
   bool utiliseCouleur;      // doit-on utiliser la couleur de base de l'objet en plus de celle de la texture?
   int afficheTexelFonce;    // un texel noir doit-il être affiché 0:noir, 1:mi-coloré, 2:transparent?
};

uniform sampler2D laTexture;

/////////////////////////////////////////////////////////////////

in Attribs {
   vec4 couleur;
   vec3 normale;
   vec3 obsVec;
   vec3 lightVec[2];
   vec3 spotDir[2];
} AttribsIn;

out vec4 FragColor;

float calculerSpot( in vec3 D, in vec3 L )
{
   float spotFactor = 0.0;
   float cos_delta= cos(radians(LightSource.spotAngleOuverture));
   float cos_inner= cos_delta;
   float cos_outer= pow(cos_delta, 1.01 + 0.5 * LightSource.spotExponent);
   float cos_gamma= max( dot( normalize( L),normalize( D) ), 0.0 ); 
   
   if (cos_gamma > cos_delta){

      //opengl or direct 3d
      spotFactor= utiliseDirect ? pow(cos_gamma,LightSource.spotExponent) : smoothstep ( cos_outer, cos_inner , cos_gamma );   
   }
  

   return( spotFactor );
}

vec4 calculerReflexion( in vec3 L, in vec3 N, in vec3 O, in vec3 D )
{
   vec4 coulp = vec4(0.0,0.0,0.0,0.0);
   coulp += FrontMaterial.ambient * LightSource.ambient;
   
   float NdotL = max( 0.0, dot( N, L ) );

   coulp += FrontMaterial.diffuse * LightSource.diffuse * NdotL;

   // calcul de la composante spéculaire (selon Phong ou Blinn)


   float NdotHV = max( 0.0, ( utiliseBlinn ) ? dot( normalize( L + O ), N ) : dot( reflect( -L, N ), O ) );
   coulp += FrontMaterial.specular * LightSource.specular *pow( NdotHV, FrontMaterial.shininess );

   coulp=coulp*calculerSpot(D,L);
   coulp = (!utiliseCouleur) ? vec4( 0.2, 0.2, 0.2, 1.0 ) : coulp;
   return( coulp );
}

void main( void )
{
   // ...

   vec3 N = normalize( AttribsIn.normale ); // vecteur normal
  // vec3 N = normalize( gl_FrontFacing ? AttribsIn.normale : -AttribsIn.normale);
   vec3 O = normalize( AttribsIn.obsVec );  // position de l'observateur

   vec3 L[2];
   vec3 D[2];
   for(int i=0; i<2; i++){
      L[i] = normalize( AttribsIn.lightVec[i] ); // vecteur vers la source lumineuse
      D[i] = normalize(AttribsIn.spotDir[i]);
   }

   // assigner la couleur finale
   //FragColor = AttribsIn.couleur;
   FragColor = vec4( 0.5, 0.5, 0.5, 1.0 ); // gris moche!
   // ajout de l’émission et du terme ambiant du modèle d’illumination

   vec4 coul = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;
   // calcul de la composante ambiante de la 1e source de lumière
   
   for(int i=0; i<2; i++){
      coul +=  calculerReflexion( L[i], N, O ,D[i]);
      
   }
   
   
   FragColor = (typeIllumination==0) ? AttribsIn.couleur : clamp( coul, 0.0, 1.0 );
   if ( afficheNormales ) FragColor = vec4(N,1.0);
}

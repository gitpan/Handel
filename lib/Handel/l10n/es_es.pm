## no critic
# $Id: es_es.pm 1444 2006-09-30 00:39:14Z claco $
package Handel::L10N::es_es;
use strict;
use warnings;
use utf8;
use vars qw/%Lexicon/;

BEGIN {
    use base qw/Handel::L10N/;
}

%Lexicon = (
    Language => 'Spanish',

    COMPAT_DEPRECATED =>
      'Handel::Compat esta obsoleta y dejará de existir en futuras versiones.',

    COMPCLASS_NOT_LOADED =>
      'El componente de clase [_1] [_2] no se ha podido cargar',

    PARAM1_NOT_HASHREF => 'El parámetro 1 no es una referencia a un HASH',

    PARAM1_NOT_HASHREF_CARTITEM =>
      'El parámetro 1 no es una referencia a un HASH ni un Handel::Cart::Item',

    PARAM1_NOT_HASHREF_CART =>
      'El parámetro 1 no es una referencia a un HASH ni un Handel::Cart',

    PARAM1_NOT_HASHREF_ORDER =>
      'El parámetro 1 no es una referencia a un HASH ni un Handel::Order',

    PARAM1_NOT_CHECKOUT_PHASE =>
      'El parámetro 1 no contiene un valor válido para CHECKOUT_PHASE_*',

    PARAM1_NOT_CODEREF =>
      'El parámetro 1 no es una referencia a CODE (código)',

    PARAM1_NOT_CHECKOUT_MESSAGE =>
      'El parámetro 1 no es un objeto Handel::Checkout::Message ni un mensaje de texto',

    PARAM1_NOT_HASH_CARTITEM_ORDERITEM =>
'El parámetro 1 no es una referencia a un HASH, un Handel::Cart::Item ni un Handel::Order::Item',

    PARAM1_NOT_ARRAYREF_STRING => 'El parámetro 1 no es una referencia a un ARRAY ni una cadena',

    PARAM2_NOT_HASHREF => 'El parámetro 2 no es una referencia a un HASH',

    CARTPARAM_NOT_HASH_CART =>
      'La referencia al carro(Cart) no es una referencia a un HASH ni un Handel::Cart',

    COLUMN_NOT_SPECIFIED => 'No se ha especificado ninguna columna',

    COLUMN_NOT_FOUND => 'La columna [_1] no existe',

    COLUMN_VALUE_EXISTS => 'El valor [_1] ya existe',

    CONSTRAINT_NAME_NOT_SPECIFIED => 'El nombre de la condición(constraint) no ha sido especificado',

    CONSTRAINT_NOT_SPECIFIED => 'La condición no ha sido especificada',

    UNKNOWN_RESTORE_MODE => 'Modo de recuperación(restore) desconocido',

    HANDLER_EXISTS_IN_PHASE =>
'Ya existe un manejador(handler) en la fase ([_1]) para la preferencia ([_2]) desde el plugin ([_3])',

    CONSTANT_NAME_ALREADY_EXISTS =>
      'La constante llamada [_1] ya existe en Handel::Constants',

    CONSTANT_VALUE_ALREADY_EXISTS =>
      'Ya existe el valor [_1] como valor constante de fase',

    CONSTANT_EXISTS_IN_CALLER =>
      'La constante llamada [_1] ya existe en [_2]',

    NO_ORDER_LOADED => 'No hay ninguna orden asociada con este proceso de checkout',

    CART_NOT_FOUND =>
      'No he podido encontrar ningún carro con el criterio de búsqueda provisto',

    ORDER_CREATE_FAILED_CART_EMPTY =>
      'No he podido crear una nueva orden porque el carro provisto está vacio',

    ROLLBACK_FAILED => 'Transacción abortada. El rollback ha fallado: [_1]',

    QUANTITY_GT_MAX =>
'La cantidad solicitada ([_1]) es mayor que la máxima permitida ([_2])',

    CURRENCY_CODE_INVALID => 'El código monetario [_1] es invalido o está mal formado',

    UNHANDLED_EXCEPTION => 'Ha ocurrido un error desconocido',

    CONSTRAINT_EXCEPTION => 'Los campos provistos no cumplen una condición de la base de datos',

    ARGUMENT_EXCEPTION =>
      'El argumento provisto es invalido o de un tipo incorrecto',

    XSP_TAG_EXCEPTION =>
      'El tag está fuera de ámbito o falta un tag hijo solicitado',

    ORDER_EXCEPTION =>
      'Ha ocurrido un error validando la orden actual',

    CHECKOUT_EXCEPTION => 'Ha ocurrido un error durante el proceso de checkout',

    STORAGE_EXCEPTION => 'Ha ocurriodo un error cargando el storage',

    VALIDATION_EXCEPTION =>
      'No se han podido escribir los datos porque no satisfasen la validación',

    VIRTUAL_METHOD => 'Metodo virtual no implementado',

    NO_STORAGE => 'No se ha suministrado el storage',

    NO_RESULT => 'No existe o no ha sido suministrado el resultado',

    NOT_CLASS_METHOD => 'No es un metodo de clase',

    FVS_REQUIRES_ARRAYREF =>
      'FormValidator::Simple requiere un perfil basado en un ARRAYREF',

    DFV_REQUIRES_HASHREF =>
      'Data::FormValidator requiere un perfil basado en un HASHREF',

    PLUGIN_HAS_NO_REGISTER =>
      'Se ha intentado registrar un plugin que no define register',

    ADD_CONSTRAINT_EXISTING_SCHEMA =>
      'No se puede agregar condiciones a una instancia de schema ya existente',

    REMOVE_CONSTRAINT_EXISTING_SCHEMA =>
      'No se puede quitar condiciones a una instancia de schema ya existente',

    SETUP_EXISTING_SCHEMA => 'Una instancia del schema ya ha sido inicializada',

    COMPDATA_EXISTING_SCHEMA =>
      'No se puede asignar [_1] a una instancia de schema ya existente',

    ITEM_RELATIONSHIP_NOT_SPECIFIED => 'No se ha definido ninguna relacion para el item',

    ITEM_STORAGE_NOT_DEFINED => 'No se ha definido item storage o item storage class',

    SCHEMA_SOURCE_NOT_SPECIFIED => 'No se ha especificado ningún schema_source',

    SCHEMA_CLASS_NOT_SPECIFIED => 'No se ha especificado ningún schema_class',

    SCHEMA_SOURCE_NO_RELATIONSHIP =>
      'El origen [_1] no tiene ninguna relación llamada [_2]',

    TAG_NOT_ALLOWED_IN_OTHERS =>
      'El tag [_1] no es valido dentro de otros Handel tags',

    TAG_NOT_ALLOWED_HERE => 'El tag [_1] no es valido aquí',

    TAG_NOT_ALLOWED_IN_TAG => 'El tag [_1] no es valido dentro del tag [_2]'
);

1;
__END__

=head1 NAME

Handel::L10N::es_es - Handel Language Pack: Spanish

=head1 AUTHOR

    Diego Kuperman
    CPAN ID: DIEGOK
    diego@freekeylabs.com
    http://diego.kuperman.com.ar/

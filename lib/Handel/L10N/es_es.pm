## no critic
# $Id: es_es.pm 1416 2006-09-15 03:45:35Z claco $
package Handel::L10N::es_es;
use strict;
use warnings;
use utf8;
use vars qw/%Lexicon/;

BEGIN {
    use base qw/Handel::L10N/;
};

%Lexicon = (
    "Language" =>
        "Español",

    ## Base exceptions
    "An unspecified error has occurred" =>
        "Un error no especificado ha ocurrido",

    "The supplied field(s) failed database constraints" =>
        "El/Los campo/s provisto/s no coinciden con los definidos en la base de datos",

    "The argument supplied is invalid or of the wrong type" =>
        "El argumento provisto es invalido o del tipo equivocado",

    "Required modules not found" =>
        "Modulos necesarios no encontrados",

    "The quantity requested ([_1]) is greater than the maximum quantity allowed ([_2])" =>
        "La cantidad solicitada ([_1]) es mayor que la cantidad maxima permitida ([_2])",

    "An error occurred while while creating or validating the current order" =>
        "Un error a ocurrido mientras se creaba o validaba la orden actual",

    "An error occurred during the checkout process" =>
        "Un error a ocurrido durante el proceso de verificación (checkout)",

    ## param 1 violations
    "Param 1 is not a HASH reference" =>
        "El parametro 1 no es una referencia a un HASH",

    "Cart reference is not a HASH reference or Handel::Cart" =>
        "La referencia al Cart no es una referencia a un HASH o un Handel::Cart",

    "Param 1 is not a HASH reference or Handel::Cart::Item" =>
        "El parametro 1 no es una referencia a un HASH ni un Handel::Cart::Item",

    "Param 1 is not a HASH reference, Handel::Order::Item or Handel::Cart::Item" =>
        "El parametro 1 no es una referencia a un HASH, un Handel::Order::Item o un Handel::Cart::Item",

    "Unknown restore mode" =>
        "Modo de recuperacion desconocido",

    "Currency code '[_1]' is invalid or malformed" =>
        "El codigo monetario '[_1]' es invalido o está mal formado",

    "Param 1 is not a a valid CHECKOUT_PHASE_* value" =>
        "El parametro 1 no es un valor CHECKOUT_PHASE_* valido",

    "Param 1 is not a CODE reference" =>
        "El parametro 1 no es una referencia a un CODE",

    "Param 1 is not an ARRAY reference" =>
        "El parametro 1 no es una referencia a un ARRAY",

    "Param 1 is not an ARRAY reference or string" =>
        "El parametro 1 no es un string ni una referencia a un ARRAY",

    "Param 1 is not a HASH reference, Handel::Order object, or order id" =>
        "El parametro 1 no es una referencia a un ARRAY, un Handel::Order ni un id de orden",

    "Param 1 is not a Handel::Checkout::Message object or text message" =>
        "El parametro 1 no es un Handel::Checkout::Message ni el texto del mensaje",

    ## Taglib exceptions
    "Tag '[_1]' not valid inside of other Handel tags" =>
        "El tag '[_1]' no es valido dentro de otros tags de Handel",

    "Tag '[_1]' not valid here" =>
        "El tag '[_1]' no es valido aquí",

    ## naughty bits
    "has invalid value" =>
        "tiene un valor invalido",

    "[_1] value already exists" =>
        "el valor [_1] ya existe",

    ## Order exceptions
    "Could not find a cart matching the supplid search criteria" =>
        "No es posible encontrar un carro con el criterio de búsqueda suministrado",

    "Could not create a new order because the supplied cart is empty" =>
        "No es posible crear una nueva orden de compra porque el carro suministrado esta vacio",

    ## Checkout exception
    "No order is assocated with this checkout process" =>
        "Ninguna orden está asociada a este proceso de verificación (checkout)",
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

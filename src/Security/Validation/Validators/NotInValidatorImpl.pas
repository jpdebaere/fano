{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit NotInValidatorImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    ListIntf,
    ValidatorIntf,
    InValidatorImpl;

type

    (*!------------------------------------------------
     * basic class having capability to
     * validate data that must not included in given list of values
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-------------------------------------------------*)
    TNotInValidator = class(TInValidator)
    protected
        (*!------------------------------------------------
         * actual data validation
         *-------------------------------------------------
         * @param dataToValidate input data
         * @return true if data is valid otherwise false
         *-------------------------------------------------*)
        function isValidData(var dataToValidate : string) : boolean; override;
    public
        (*!------------------------------------------------
         * constructor
         *-------------------------------------------------*)
        constructor create(const validValues : array of string);
    end;

implementation

uses

    SysUtils;

resourcestring

    sErrFieldMustNotIn = 'Field %s must not in given values ';


    (*!------------------------------------------------
     * constructor
     *-------------------------------------------------*)
    constructor TNotInValidator.create(const validValues : array of string);
    begin
        inherited create(validValues);
        errorMsgFormat := sErrFieldMustNotIn;
    end;

    (*!------------------------------------------------
     * actual data validation
     *-------------------------------------------------
     * @param dataToValidate input data
     * @return true if data is valid otherwise false
     *-------------------------------------------------*)
    function TNotInValidator.isValidData(const dataToValidate : string) : boolean;
    begin
        result := not (inherited isValidData(dataToValidate));
    end;
end.
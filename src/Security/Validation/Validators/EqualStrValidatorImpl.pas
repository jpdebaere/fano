{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit EqualStrValidatorImpl;

interface

{$MODE OBJFPC}
{$H+}

uses

    ReadOnlyListIntf,
    ValidatorIntf,
    RequestIntf,
    CompareStrValidatorImpl;

type

    (*!------------------------------------------------
     * basic class having capability to
     * validate data equality against a reference string
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-------------------------------------------------*)
    TEqualStrValidator = class(TCompareStrValidator)
    protected

        function compareStrWithRef(
            const astr: string;
            const refStr : string
        ) : boolean; override;
    end;

implementation

resourcestring

    sErrFieldMustBeEqualString = 'Field %s must be equal to ';

    (*!------------------------------------------------
     * constructor
     *-------------------------------------------------*)
    constructor TEqualStrValidator.create(const refStr : string);
    begin
        inherited create(sErrFieldMustBeEqualStr + refStr);
        fRefStr := refStr;
    end;

    function TEqualStrValidator.compareStrWithRef(
        const astr: string;
        const refStr : string
    ) : boolean;
    begin
        result := (compareStr(astr, efStr) = 0);
    end;

end.

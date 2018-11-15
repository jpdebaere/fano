{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

unit ModelPresenterIntf;

interface

{$MODE OBJFPC}

uses

    ViewIntf;

type

    (*!------------------------------------------------
     * interface for model that can display/visualize
     * data to view
     *
     * @author Zamrony P. Juhara <zamronypj@yahoo.com>
     *-----------------------------------------------*)
    IModelPresenter = interface
        ['{16CB66AA-A3D1-4F41-8A0D-86BBD4227071}']

        (*!----------------------------------------------
         * display model data to view
         *-----------------------------------------------
         * @param targetView view where to render data
         * @return view instance
         *-----------------------------------------------*)
        function display(const targetView : IView) : IView;
    end;

implementation

end.
package coconut.react;

#if !macro
import coconut.ui.RenderResult;
import tink.state.Observable;
import js.html.Element;
import coconut.react.*;

using tink.CoreApi;

class Renderable {
  var __rendered:Observable<RenderResult>;
  var __wrapper:ReactElement;
  
  public function new(rendered, ?key) {
    __rendered = rendered;
    init();
  }
  
  function init() {}

  public function reactify():RenderResult {
    if (this.__wrapper == null)
      this.__wrapper = React.createComponent(Wrapper, untyped {
        key: this.viewId,
        rendered: __rendered,
        componentWillMount: componentWillMount,
        componentDidMount: componentDidMount,
        componentDidUpdate: componentDidUpdate,
        componentWillUnmount: componentWillUnmount,
      });
    return this.__wrapper;
  }
  
  function componentWillMount() {}
  function componentDidMount() {}
  function componentDidUpdate() {}
  function componentWillUnmount() {}

  // inline function __make(tag:CreateElementType, attr:Dynamic, ?children:Array<ReactChild>)
    // return React.createElement(tag, attr, children);

  macro function hxx(e);
  
  function div(attr:{}, ?children)//TODO: this does not belong here at all
    return React.createElement('div', attr, children);

  function span(attr:{ ?key: Dynamic }, ?children)
    return React.createElement('span', attr, children);

  #if !react_native
  public function mountInto(container:Element): { function unmount():Bool; } {
    ReactDom.render(
      reactify(), 
      container
    );
    return {
      unmount: function () return ReactDom.unmountComponentAtNode(container),
    }
  }
  #end
}

#if !react_native
#if react
private typedef ReactDom = react.ReactDOM;
#else

@:native('ReactDOM')
private extern class ReactDom {
  static function render(element:ReactElement, container:Element, ?callback:Void -> Void):ReactElement;
  static function unmountComponentAtNode(container:Element):Bool;
}
#end
#end

private class Wrapper extends ReactComponent<
  { 
    rendered: Observable<RenderResult>,
    componentWillMount:Void->Void,
    componentDidMount:Void->Void,
    componentDidUpdate:Void->Void,
    componentWillUnmount:Void->Void,
  }, 
  { view: RenderResult }
> { 
  
  var link:CallbackLink;
  
  function new(props) {
    super(props);
    
    state = { view: @:privateAccess props.rendered.value };
  }
  
  override function componentWillMount() {
    link = @:privateAccess props.rendered.bind(function(r) setState(function (_, _) return { view: r }));
    props.componentWillMount();
  }
  
  override function componentDidMount() {
    props.componentDidMount();
  }
  
  override function componentDidUpdate(_, _) {
    props.componentDidUpdate();
  }
  
  override function componentWillUnmount() {
    if(link != null) {
      link.dissolve();
      link = null;
    }
    props.componentWillUnmount();
  }
  
  override function render():ReactElement 
    return this.state.view;
    
}
#else
class Renderable {
  macro function hxx(_, e) {
    #if coconut_ui
    return coconut.ui.macros.HXX.parse(e);
    #else
      #error 'Requires coconut.ui';
    #end
  }
}
#end
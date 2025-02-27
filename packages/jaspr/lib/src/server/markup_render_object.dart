import 'dart:convert';

import '../../server.dart';

const formatOutput = kDebugMode || kGenerateMode;

class MarkupRenderObject extends RenderObject {
  String? tag;
  String? id;
  String? classes;
  Map<String, String>? styles;
  Map<String, String>? attributes;

  String? text;
  bool? rawHtml;

  List<MarkupRenderObject> children = [];

  MarkupRenderObject? parent;

  @override
  RenderObject createChildRenderObject() {
    return MarkupRenderObject();
  }

  @override
  void updateElement(String tag, String? id, String? classes, Map<String, String>? styles,
      Map<String, String>? attributes, Map<String, EventCallback>? events) {
    this.tag = tag;
    this.id = id;
    this.classes = classes;
    this.styles = styles;
    this.attributes = attributes;
  }

  @override
  void updateText(String text, [bool rawHtml = false]) {
    this.text = text;
    this.rawHtml = rawHtml;
  }

  @override
  void skipChildren() {
    // noop
  }

  @override
  void attach(MarkupRenderObject? parent, MarkupRenderObject? after) {
    if (parent == null) return;

    var children = parent.children;
    children.remove(this);
    if (after == null) {
      children.insert(0, this);
    } else {
      var index = children.indexOf(after);
      children.insert(index + 1, this);
    }
  }

  @override
  void remove() {
    parent?.children.remove(this);
    parent = null;
  }

  String renderToHtml() {
    if (text case var text?) {
      if (rawHtml == true) {
        return text;
      } else {
        return htmlEscape.convert(text);
      }
    } else if (tag case var tag?) {
      var output = StringBuffer();
      tag = tag.toLowerCase();
      _domValidator.validateElementName(tag);
      output.write('<$tag');
      if (id case String id) {
        output.write(' id="${_attributeEscape.convert(id)}"');
      }
      if (classes case String classes when classes.isNotEmpty) {
        output.write(' class="${_attributeEscape.convert(classes)}"');
      }
      if (styles case var styles? when styles.isNotEmpty) {
        var props = styles.entries.map((e) => '${e.key}: ${e.value}');
        output.write(' style="${_attributeEscape.convert(props.join('; '))}"');
      }
      if (attributes case var attrs? when attrs.isNotEmpty) {
        for (var attr in attrs.entries) {
          _domValidator.validateAttributeName(attr.key);
          if (attr.value.isNotEmpty) {
            output.write(' ${attr.key}="${_attributeEscape.convert(attr.value)}"');
          } else {
            output.write(' ${attr.key}');
          }
        }
      }
      var selfClosing = _domValidator.isSelfClosing(tag);
      if (selfClosing) {
        output.write('/>');
      } else {
        output.write('>');
        var childOutput = <String>[];
        for (var child in children) {
          childOutput.add(child.renderToHtml());
        }
        var fullChildOutput = childOutput.fold<String>('', (s, o) => s + o);
        if (formatOutput && (fullChildOutput.length > 80 || fullChildOutput.contains('\n'))) {
          output.write('\n');
          for (var child in childOutput) {
            output.writeln('  ${child.replaceAll('\n', '\n  ')}');
          }
        } else {
          output.write(fullChildOutput);
        }
        output.write('</$tag>');
      }
      return output.toString();
    } else {
      assert(parent == null);
      var output = StringBuffer();
      for (var child in children) {
        output.writeln(child.renderToHtml());
      }
      return output.toString();
    }
  }

  final _attributeEscape = HtmlEscape(HtmlEscapeMode.attribute);
  final _domValidator = DomValidator();
}

/// DOM validator with sane defaults.
class DomValidator {
  static final _attributeRegExp = RegExp(r'^[a-z](?:[a-z0-9\-_]*[a-z0-9]+)?$');
  static final _elementRegExp = _attributeRegExp;
  static const _selfClosing = <String>{
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'path',
    'source',
    'track',
    'wbr',
  };
  final _tags = <String>{};
  final _attrs = <String>{};

  void validateElementName(String tag) {
    if (_tags.contains(tag)) return;
    if (_elementRegExp.matchAsPrefix(tag) != null) {
      _tags.add(tag);
    } else {
      throw ArgumentError('"$tag" is not a valid element name.');
    }
  }

  void validateAttributeName(String name) {
    if (_attrs.contains(name)) return;
    if (_attributeRegExp.matchAsPrefix(name) != null) {
      _attrs.add(name);
    } else {
      throw ArgumentError('"$name" is not a valid attribute name.');
    }
  }

  bool isSelfClosing(String tag) {
    return _selfClosing.contains(tag);
  }
}

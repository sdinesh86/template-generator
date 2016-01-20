{View, SelectListView, $$, $, TextEditorView } = require 'atom-space-pen-views'
TemplateGeneratorUtilities = require './template-generator-utilities'
_ = require 'underscore'
CSON = require 'season'

buildTextEditor = require './build-text-editor'

module.exports =
class FieldsListView extends View

  @content: ->
    @div tabIndex: -1, class:'tg-fields-list-view inset-panel', =>
      @div class:'panel-heading', =>
        @span 'List of Fields you would like to replace in the files and file names'
      @div class:'panel-body', =>
        @div class:'block fields-list select-list', =>
          @ol class:'fields-group list-group', outlet:'fieldsList'
        @div class:'block btn-toolbar', =>
          @div class:'btn-group', =>
            @button 'Create', class:'btn btn-success', click:'createTheTemplates', 'tabindex':100
            @button 'Cancel', class:'btn btn-error', click:'close', 'tabindex':101

  initialize: ( {template, selectedPath}={} ) ->
    @template = template
    @selectedPath = selectedPath

    atom.commands.add @element,
      'tg-fields-list-view:focus-next': ( e ) => @focusNextInput(1)
      'tg-fields-list-view:focus-previous': ( e ) => @focusPreviousInput(-1)
      'core:cancel': ( e ) => @close()


  # createTheTemplates:
  #
  # * `` The [description] as {[type]}.
  #
  # Returns the [Description] as `undefined`.
  createTheTemplates: ( e ) ->
    self = $(e.target)
    fields = @fieldsList.children('li')
    sFieldsArray = []

    # Loop through the UI and get the fields and thier names
    _.each fields, ( fElement ) ->
      fieldName = $(fElement).data( 'field-item-data' )
      fieldValue = fElement.children[0].getModel().getText()
      sFieldsArray.push [fieldName, fieldValue]

    transformedTemplate = TemplateGeneratorUtilities.tansformTemplateObjectWithFields @template, sFieldsArray
    TemplateGeneratorUtilities.generateFilesUsingTemplateObject transformedTemplate, @selectedPath

    @close()


  focusNextInput: ( direction ) ->

    elements = $(@fieldsList).find( 'atom-text-editor' ).toArray()
    focusedElement = _.find elements, ( el ) -> $(el).hasClass('is-focused')
    focusedIndex = elements.indexOf focusedElement
    console.log focusedElement, elements
    focusedIndex = focusedIndex + direction
    focusedIndex = 0 if focusedIndex >= elements.length
    focusedIndex = elements.length - 1 if focusedIndex < 0

    elements[focusedIndex].focus()
    # elements[focusedIndex].getModel?().selectAll()

  focusPreviousInput: ( direction ) ->


  # close: Close the view
  #
  # Returns the [Description] as `undefined`.
  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()

  viewForItem : ( item, nIndex ) ->
    textEditor = buildTextEditor
      mini: true
      tabLength: 2
      softTabs: true
      softWrapped: false
      placeholderText: item

    $$ ->
      @li =>
        @subview "item-#{nIndex}", new TextEditorView(editor: textEditor)

  # populateFields: Populate all the fields in the modal panel
  #
  # * `fileds ` The [description] as {[type]}.
  #
  # Returns the [Description] as `undefined`.
  populateFields: ( fields ) ->
    @fieldsList.empty()
    nTabIndex = 1
    for field in fields
      itemView = $(@viewForItem(field, nTabIndex))
      itemView.data('field-item-data', field)
      @fieldsList.append itemView
      nTabIndex++



  # attach: Attach the view to atom and display it
  #
  # Returns the [Description] as `undefined`.
  attach: ->
    @panel = atom.workspace.addModalPanel(item: this)
    fieldsList = TemplateGeneratorUtilities.parseTemplate( @template )
    @populateFields(_.uniq fieldsList)

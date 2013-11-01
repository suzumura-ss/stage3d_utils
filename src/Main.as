package 
{
	import alternativa.engine3d.controllers.SimpleObjectController;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.primitives.Plane;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.alternativa.LuminanceAndAlphaTextureMaterial;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	import info.smoche.alternativa.RenderTextureResource;
	import info.smoche.alternativa.TextureCamera3D;
	import info.smoche.stage3d.AGALGeometry;
	import info.smoche.stage3d.AGALProgram;
	import info.smoche.utils.LookAt3D;
	import info.smoche.utils.Utils;
	
	/**
	 * ...
	 * @author 
	 */
	
	//[SWF(backgroundColor = "0x909090", width = "800", height = "600")]
	
	public class Main extends Sprite 
	{
		private var _stage3d:Stage3D;
		private var _root:Object3D;
		private var _camera:TextureCamera3D;
		private var _controller:SimpleObjectController;
		
		private var _sphere:Mesh;
		private var _mirror:Mesh;
		private var _mirrorTexture0:RenderTextureResource;
		private var _mirrorTexture1:RenderTextureResource;
		
		private var _agalProgram:AGALProgram;
		private var _agalGeom:AGALGeometry;
		
		[Embed(source = "500x250.jpg")] private const TEXTURE:Class;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage3d = stage.stage3Ds[0];
			_stage3d.addEventListener(Event.CONTEXT3D_CREATE, onContent3DCreate);
			_stage3d.requestContext3D();
		}
		
		private function onContent3DCreate(e:Event):void
		{
			_stage3d.removeEventListener(Event.CONTEXT3D_CREATE, onContent3DCreate);
			
			_root = new Object3D();
			_camera = new TextureCamera3D(0.01, 100000000);
			_camera.view = new View(stage.stageWidth, stage.stageHeight, false, 0x202020, 0, 4);
			addChild(_camera.view);
			addChild(_camera.diagram);
			
			_root.addChild(_camera);
			_controller = new SimpleObjectController(stage, _camera, 200, 3, -0.1);
			var center:Number = -Math.PI / 2.0;
			_controller.maxPitch = center + Math.PI / 2.0;
			_controller.minPitch = center - Math.PI / 2.0;
			_controller.lookAt(new LookAt3D());
			
			// 天頂
			var m:Mesh = new Box();
			m.z = 500;
			m.setMaterialToAllSurfaces(new FillMaterial(0xff8080));
			_root.addChild(m);
			
			// 地面
			m = new Box();
			m.z = -500;
			m.setMaterialToAllSurfaces(new FillMaterial(0xc04040));
			_root.addChild(m);
			
			// 正面
			m = new Box();
			m.x = 500;
			m.setMaterialToAllSurfaces(new FillMaterial(0x80ff80));
			_root.addChild(m);
			
			// 後方
			m = new Box();
			m.x = -500;
			m.setMaterialToAllSurfaces(new FillMaterial(0x40c040));
			_root.addChild(m);
			
			// 左
			m = new Box();
			m.y = 500;
			m.setMaterialToAllSurfaces(new FillMaterial(0x8080ff));
			_root.addChild(m);
			
			// 右
			m = new Box();
			m.y = -500;
			m.setMaterialToAllSurfaces(new FillMaterial(0x4040c0));
			_root.addChild(m);
			
			/*=== sphere ===*/
			_sphere = m = new GeoSphere();
			m.x = 700;
			var bmp:Bitmap = new TEXTURE() as Bitmap;
			var tr:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource(bmp.bitmapData);
			m.setMaterialToAllSurfaces(new LuminanceAndAlphaTextureMaterial(tr, 0.8, _stage3d.context3D));
			_root.addChild(m);
			
			BitmapTextureResourceLoader.flipH = false;
			BitmapTextureResourceLoader.loadURL("forest.jpg", function(tr:NonMipmapBitmapTextureResource):void {
				m = new GeoSphere(2000, 4, true);
				var w:WireFrame = WireFrame.createEdges(m, 0, 1, 2);
				_root.addChild(w);
				
				var t:NonMipmapTextureMaterial = new NonMipmapTextureMaterial(tr, 1, _stage3d.context3D);
				m.setMaterialToAllSurfaces(t);
				_root.addChild(m);
				
				uploadResouces();
			}, function(e:Error):void {
				Utils.Trace(e);
			});
			
			/*=== panel ===*/
			_mirrorTexture0 = new RenderTextureResource(new Point(512, 512));
			_mirrorTexture1 = new RenderTextureResource(new Point(512, 512));
			_mirror = m = new Plane(400, 200, 1, 1, true, false,
				new NonMipmapTextureMaterial(_mirrorTexture0, 1, _stage3d.context3D),
				new NonMipmapTextureMaterial(_mirrorTexture1, 1, _stage3d.context3D)
			);
			m.rotationZ = Math.PI / 2.0;
			m.rotationX = Math.PI / 4.0;
			m.x = 300;
			m.z = 100;
			_root.addChild(m);
			
			
			/*=== Local program ===*/
			_agalProgram = new AGALProgram(_stage3d.context3D, ["m44 op, va0, vc0"], ["#color=0", "mov oc, fc0"]);
			var verts:Vector.<Number> = Vector.<Number>([
				// x, y, z
				-0.9, -0.9, 0,
				 0.9, -0.9, 0,
				 0.9,  0.9, 0,
				-0.9,  0.9, 0,
			]);
			var index:Vector.<uint> = Vector.<uint>([
				0, 1, 2,
				0, 2, 3,
			]);
			_agalGeom = new AGALGeometry(_stage3d.context3D, verts, index, false);
			
			
			/****/
			uploadResouces();
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
		}
		
		private function uploadResouces():void
		{
			for each (var resource:Resource in _root.getResources(true)) {
				if (!resource.isUploaded) resource.upload(_stage3d.context3D);
			}
		}
		
		private function onEnterFrame(e:Event):void
		{
			_sphere.rotationX += 0.01;
			_sphere.rotationY += 0.02;
			_controller.update();
			
			// alternativa3dでテクスチャへ描画: 前方上側のパネルの表面
			_camera.renderToTexture(_stage3d, _mirrorTexture0.texture(), true);
			
			// 生のStage3Dでテクスチャへ描画: 前方上側のパネルの裏面
			var mat:Matrix3D = new Matrix3D();
			mat.identity();
			_agalProgram.context(function(ctx:Context3D):void {
				_mirrorTexture1.attach();
				ctx.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
				ctx.clear(1, 1, 1, 1);
				
				mat.appendTranslation(0.3, 0, 0);
				_agalProgram.setMatrix3D("modelViewProjectionMatrix", mat);
				_agalProgram.setNumbers("color", 1, 0, 0, 0.5);
				_agalProgram.drawGeometry(_agalGeom);
				
				mat.appendTranslation(-0.6, 0, 0);
				_agalProgram.setMatrix3D("modelViewProjectionMatrix", mat);
				_agalProgram.setNumbers("color", 0, 1, 0, 0.5);
				_agalProgram.drawGeometry(_agalGeom);
				
				ctx.setRenderToBackBuffer();
			});
			
			// Viewへ描画
			_camera.render(_stage3d)
		}
		
		private function onResize(e:Event):void
		{
			_camera.view.width = stage.stageWidth;
			_camera.view.height = stage.stageHeight;
		}
	}
}
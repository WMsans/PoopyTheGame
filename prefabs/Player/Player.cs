using Godot;
using System;

namespace PoopyTheGame.Player;

public partial class Player : Node2D
{
    private static readonly float QuarterRotation = float.DegreesToRadians(90);
    
    [ExportGroup("Physics Properties")]
    [Export] public double Gravity { get; set; } = 100;
    [Export] public double Acceleration { get; set; } = 10;
    [Export] public double Deceleration { get; set; } = 10;
    [Export(PropertyHint.Range, "0,1")] public double FrictionPercent { get; set; } = 0.2;

    private double _speed;
    private RayCast2D _rayCast;

    public override void _Ready()
    {
        _rayCast = GetNode<RayCast2D>("RayCast2D");
    }

    public override void _PhysicsProcess(double delta)
    {
        if (Input.IsActionPressed("left"))
        {
            _speed -= Acceleration;
        }
        else if (Input.IsActionPressed("right"))
        {
            _speed += Acceleration;
        }
        else
        {
            if (_speed > 0)
            {
                _speed -= Deceleration;
            }
            else if (_speed < 0)
            {
                _speed += Deceleration;
            }
        }
        
        _rayCast.ForceRaycastUpdate();
        var obj = _rayCast.GetCollider();
        var baseVector = Vector2.Right * (float)_speed;
        if (obj is StaticBody2D body)
        {
            baseVector = baseVector.Rotated(body.Rotation);
            Rotation = body.Rotation;
        }
        else
        {
            Rotation = 0;
            baseVector += Vector2.Down * (float)Gravity;
        }
        Position += baseVector * (float)delta;
    }
}
